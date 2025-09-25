# IMDSv2 Implementation Guide

This document explains the implementation of IMDSv2 (Instance Metadata Service version 2) in your EC2 instances and its security benefits.

## What is IMDSv2?

IMDSv2 is a more secure version of the EC2 Instance Metadata Service that provides protection against SSRF (Server-Side Request Forgery) attacks. It requires session tokens and has additional security measures compared to IMDSv1.

## Key Differences: IMDSv1 vs IMDSv2

### IMDSv1 (Legacy)
- Simple HTTP GET requests
- No authentication required
- Vulnerable to SSRF attacks
- Direct access to metadata

### IMDSv2 (Secure)
- Requires session tokens
- Token-based authentication
- Protection against SSRF attacks
- Two-step process: get token, then access metadata

## Changes Made

### 1. Terraform Configuration Updates

I've updated your `terraform/modules/compute/compute.tf` to include IMDSv2 configuration for both frontend and backend instances:

```hcl
# Enable IMDSv2 (Instance Metadata Service version 2)
metadata_options {
  http_endpoint               = "enabled"
  http_tokens                 = "required"  # This enforces IMDSv2
  http_put_response_hop_limit = 1
  instance_metadata_tags      = "enabled"
}
```

### 2. Configuration Parameters Explained

- **`http_endpoint`**: Set to "enabled" to allow metadata access
- **`http_tokens`**: Set to "required" to enforce IMDSv2 (this is the key setting)
- **`http_put_response_hop_limit`**: Set to 1 to prevent token forwarding
- **`instance_metadata_tags`**: Set to "enabled" to allow access to instance tags via metadata

## Security Benefits

### 1. SSRF Protection
IMDSv2 protects against SSRF attacks by requiring a session token that can only be obtained from within the instance.

### 2. Token-Based Authentication
All metadata requests must include a valid session token, preventing unauthorized access.

### 3. Hop Limit Protection
The `http_put_response_hop_limit` setting prevents tokens from being forwarded to other instances.

### 4. AWS Best Practices
IMDSv2 is now the recommended approach by AWS for all new instances.

## Implementation Steps

### 1. Apply Terraform Changes
```bash
cd terraform
terraform plan
terraform apply
```

### 2. Verify IMDSv2 Configuration
```bash
cd ansible
./scripts/verify_imdsv2.sh
```

### 3. Test Your Applications
Ensure your applications work with IMDSv2 by testing:
- Application startup
- Metadata access
- AWS SDK functionality

## How IMDSv2 Works

### Step 1: Get Session Token
```bash
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
```

### Step 2: Use Token to Access Metadata
```bash
curl -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-id
```

## Application Compatibility

### AWS SDKs
Most AWS SDKs automatically support IMDSv2:
- **AWS SDK for Python (boto3)**: ✅ Supports IMDSv2
- **AWS SDK for JavaScript**: ✅ Supports IMDSv2
- **AWS SDK for Java**: ✅ Supports IMDSv2
- **AWS CLI**: ✅ Supports IMDSv2

### Custom Scripts
If you have custom scripts that access metadata, update them to use IMDSv2:

```bash
# Old IMDSv1 way (will fail with IMDSv2)
curl http://169.254.169.254/latest/meta-data/instance-id

# New IMDSv2 way
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
curl -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-id
```

## Verification Commands

### Check Current Configuration
```bash
# Check if IMDSv2 is enabled
aws ec2 describe-instances \
  --instance-ids i-1234567890abcdef0 \
  --query 'Reservations[*].Instances[*].MetadataOptions.HttpTokens'
```

### Test IMDSv2 Access
```bash
# Test IMDSv1 (should fail)
curl http://169.254.169.254/latest/meta-data/instance-id

# Test IMDSv2 (should succeed)
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
curl -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-id
```

## Troubleshooting

### Common Issues

1. **Applications failing to start**
   - Check if applications are using IMDSv1
   - Update to use IMDSv2 or AWS SDKs

2. **Scripts failing**
   - Update custom scripts to use IMDSv2 tokens
   - Use AWS CLI instead of direct HTTP calls

3. **SDK errors**
   - Ensure you're using the latest version of AWS SDKs
   - Most SDKs automatically handle IMDSv2

### Rollback (if needed)
If you need to temporarily disable IMDSv2:

```hcl
metadata_options {
  http_endpoint               = "enabled"
  http_tokens                 = "optional"  # Allows both v1 and v2
  http_put_response_hop_limit = 1
  instance_metadata_tags      = "enabled"
}
```

## Best Practices

### 1. Token Management
- Set appropriate TTL for tokens (21600 seconds = 6 hours is recommended)
- Reuse tokens when possible to reduce API calls

### 2. Security
- Use the minimum required hop limit (1)
- Consider disabling IMDS for instances that don't need it
- Monitor for unusual metadata access patterns

### 3. Application Design
- Use AWS SDKs when possible
- Implement proper error handling for metadata access
- Cache metadata when appropriate

## Monitoring and Logging

### CloudTrail
IMDSv2 API calls are logged in CloudTrail, providing audit trails for metadata access.

### CloudWatch
Monitor for unusual patterns in metadata access or failed requests.

## Compliance

IMDSv2 helps meet various compliance requirements:
- **SOC 2**: Enhanced security controls
- **PCI DSS**: Protection against SSRF attacks
- **ISO 27001**: Improved access controls
- **AWS Well-Architected Framework**: Security best practices

## Resources

- [AWS IMDSv2 Documentation](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/configuring-instance-metadata-service.html)
- [IMDSv2 Migration Guide](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/configuring-instance-metadata-service.html#instance-metadata-transition-to-version-2)
- [AWS Security Blog - IMDSv2](https://aws.amazon.com/blogs/security/defense-in-depth-open-firewalls-reverse-proxies-ssrf-vulnerabilities-ec2-instance-metadata-service/) 