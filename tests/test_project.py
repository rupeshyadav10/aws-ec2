"""Static checks for the project - no AWS account needed.

Run from the project root:   python -m unittest discover -s tests -v
Requires PyYAML (pip install pyyaml); tests are skipped if it is missing.
"""
import re
import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

try:
    import yaml
except ImportError:  # pragma: no cover
    yaml = None


def load_template():
    """Parse a CloudFormation YAML file (handles !Ref / !Sub / !GetAtt short tags)."""
    class Loader(yaml.SafeLoader):
        pass

    def any_tag(loader, suffix, node):
        if isinstance(node, yaml.ScalarNode):
            return {suffix: loader.construct_scalar(node)}
        if isinstance(node, yaml.SequenceNode):
            return {suffix: loader.construct_sequence(node, deep=True)}
        return {suffix: loader.construct_mapping(node, deep=True)}

    Loader.add_multi_constructor("!", any_tag)
    subprocess.run([sys.executable, str(ROOT / "infrastructure" / "build_template.py")],
                   check=True, capture_output=True)
    return yaml.load((ROOT / "infrastructure" / "template.yaml").read_text(), Loader=Loader)


class BootstrapScriptTests(unittest.TestCase):
    script = (ROOT / "scripts" / "bootstrap-userdata.sh").read_text()

    def test_shell_syntax_is_valid(self):
        for name in ("bootstrap-userdata.sh", "deploy.sh", "cleanup.sh",
                     "create-ami-and-scale.sh", "test-load-balancing.sh"):
            r = subprocess.run(["bash", "-n", str(ROOT / "scripts" / name)], capture_output=True, text=True)
            self.assertEqual(r.returncode, 0, f"{name}: {r.stderr}")

    def test_no_braced_variables_that_would_break_fn_sub(self):
        self.assertNotIn("${", self.script)

    def test_installs_and_starts_apache(self):
        self.assertIn("dnf install -y httpd", self.script)
        self.assertIn("systemctl enable --now httpd", self.script)

    def test_creates_health_check_page(self):
        self.assertIn("/var/www/html/health.html", self.script)

    def test_uses_imdsv2_token(self):
        self.assertIn("latest/api/token", self.script)


@unittest.skipIf(yaml is None, "PyYAML not installed")
class TemplateTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.t = load_template()
        cls.res = cls.t["Resources"]

    def of_type(self, rtype):
        return {k: v for k, v in self.res.items() if v["Type"] == rtype}

    def test_expected_resource_types_present(self):
        for rtype in ("AWS::EC2::Instance", "AWS::EC2::EIP", "AWS::EC2::SecurityGroup",
                      "AWS::EC2::LaunchTemplate", "AWS::S3::Bucket", "AWS::IAM::Role",
                      "AWS::ElasticLoadBalancingV2::LoadBalancer",
                      "AWS::ElasticLoadBalancingV2::TargetGroup",
                      "AWS::ElasticLoadBalancingV2::Listener", "AWS::CloudWatch::Alarm"):
            self.assertTrue(self.of_type(rtype), f"missing {rtype}")

    def test_web_servers_only_accept_http_from_load_balancer(self):
        sg = self.res["WebSecurityGroup"]["Properties"]["SecurityGroupIngress"]
        http = [r for r in sg if r["FromPort"] == 80][0]
        self.assertIn("SourceSecurityGroupId", http)
        self.assertNotIn("CidrIp", http)

    def test_ssh_is_never_open_to_the_world(self):
        for name in ("WebSecurityGroup", "AdminSecurityGroup"):
            for rule in self.res[name]["Properties"]["SecurityGroupIngress"]:
                if rule["FromPort"] == 22:
                    self.assertNotEqual(rule.get("CidrIp"), "0.0.0.0/0", name)

    def test_health_check_path(self):
        tg = self.res["TargetGroup"]["Properties"]
        self.assertEqual(tg["HealthCheckPath"], "/health.html")

    def test_bucket_blocks_public_access(self):
        cfg = self.res["BackupBucket"]["Properties"]["PublicAccessBlockConfiguration"]
        self.assertTrue(all(cfg.values()))

    def test_imdsv2_required_on_launch_template(self):
        data = self.res["WebLaunchTemplate"]["Properties"]["LaunchTemplateData"]
        self.assertEqual(data["MetadataOptions"]["HttpTokens"], "required")

    def test_userdata_injected_and_bucket_placeholder_replaced(self):
        text = (ROOT / "infrastructure" / "template.yaml").read_text()
        self.assertNotIn("__USERDATA__", text)
        self.assertNotIn("__BUCKET__", text.split("backup-logs.sh <<'SCRIPT'")[0])
        self.assertIn("${BackupBucket}", text)

    def test_iam_policy_is_scoped_to_logs_prefix(self):
        stmt = self.res["WebInstanceRole"]["Properties"]["Policies"][0]["PolicyDocument"]["Statement"][0]
        self.assertEqual(stmt["Action"], "s3:PutObject")
        self.assertNotEqual(stmt["Resource"], "*")


if __name__ == "__main__":
    unittest.main()
