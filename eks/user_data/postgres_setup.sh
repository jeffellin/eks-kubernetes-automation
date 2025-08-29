#!/bin/bash

# Update system
apt-get update -y

# Install PostgreSQL (default version for Ubuntu 16.04 - 9.5)
apt-get install -y postgresql postgresql-client postgresql-contrib

# Start and enable PostgreSQL service
systemctl enable postgresql
systemctl start postgresql

# Configure PostgreSQL
sudo -u postgres psql << EOF
ALTER USER postgres PASSWORD '${postgres_password}';
CREATE DATABASE wizdb;
\q
EOF

# Configure PostgreSQL for remote connections
sudo -u postgres bash << 'EOF'
# Update postgresql.conf
echo "listen_addresses = '*'" >> /etc/postgresql/9.5/main/postgresql.conf
echo "port = 5432" >> /etc/postgresql/9.5/main/postgresql.conf

# Update pg_hba.conf for authentication
cat >> /etc/postgresql/9.5/main/pg_hba.conf << 'PGEOF'
# Allow connections from VPC CIDR
host    all             all             10.0.0.0/16            md5
# Allow connections from anywhere
host    all             all             0.0.0.0/0              md5
PGEOF
EOF

# Restart PostgreSQL to apply configuration changes
systemctl restart postgresql

# Install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i amazon-cloudwatch-agent.deb

# Create CloudWatch agent configuration
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'CWEOF'
{
    "agent": {
        "metrics_collection_interval": 60,
        "run_as_user": "root"
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/postgresql/postgresql-9.5-main.log",
                        "log_group_name": "/aws/ec2/postgres",
                        "log_stream_name": "{instance_id}/postgresql.log"
                    }
                ]
            }
        }
    },
    "metrics": {
        "namespace": "WizPostgreSQL",
        "metrics_collected": {
            "cpu": {
                "measurement": [
                    "cpu_usage_idle",
                    "cpu_usage_iowait",
                    "cpu_usage_user",
                    "cpu_usage_system"
                ],
                "metrics_collection_interval": 60
            },
            "disk": {
                "measurement": [
                    "used_percent"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "diskio": {
                "measurement": [
                    "io_time"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "mem": {
                "measurement": [
                    "mem_used_percent"
                ],
                "metrics_collection_interval": 60
            }
        }
    }
}
CWEOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
    -s

# Install s3cmd for S3 operations
apt-get install -y s3cmd

# Configure s3cmd with instance credentials (uses IAM role) for root user
cat > /root/.s3cfg << 'S3CFGEOF'
[default]
use_https = True
access_token = 
access_key = 
secret_key = 
security_token = 
host_base = s3.amazonaws.com
host_bucket = %(bucket)s.s3.amazonaws.com
cloudfront_host = cloudfront.amazonaws.com
use_mime_magic = True
delete_removed = False
encrypt = False
follow_symlinks = False
gpg_command = /usr/bin/gpg
gpg_decrypt = %(gpg_command)s -d --quiet --no-verbose --batch --yes
gpg_encrypt = %(gpg_command)s -ac --quiet --no-verbose --batch --yes
guess_mime_type = True
default_mime_type = binary/octet-stream
preserve_attrs = True
progress_meter = True
recursive = True
recv_chunk = 65536
reduced_redundancy = False
restore_api = True
send_chunk = 65536
signature_v2 = False
socket_timeout = 300
use_http_expect = False
verbosity = WARNING
website_endpoint = http://%(bucket)s.s3-website-%(location)s.amazonaws.com/
S3CFGEOF

# Create backup script
cat > /usr/bin/backup.sh << 'BACKUPEOF'
#!/bin/bash -x
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export PGPASSWORD=${postgres_password}
current_time=$(date "+%Y.%m.%d-%H.%M.%S")
new_fileName=/tmp/backup.dump.$current_time
pg_dump -v --format=c -h localhost -U postgres wizdb > $new_fileName
/usr/bin/s3cmd put $new_fileName s3://${bucket_name}/
rm -f $new_fileName
echo "Backup completed: backup.dump.$current_time uploaded to s3://${bucket_name}/"
BACKUPEOF

# Make backup script executable
chmod 0755 /usr/bin/backup.sh

# Create a sample database and table
sudo -u postgres psql -d wizdb << 'DBEOF'
CREATE TABLE sample_data (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO sample_data (name) VALUES ('Sample Entry 1'), ('Sample Entry 2'), ('Sample Entry 3');
DBEOF

# Set up backup cron job every 30 minutes
echo "*/30 * * * * root /usr/bin/backup.sh >> /var/log/postgres_backup.log 2>&1" > /etc/cron.d/postgres-backup

echo "PostgreSQL installation and configuration completed successfully" > /var/log/postgres_setup.log