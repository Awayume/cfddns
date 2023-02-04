# cfddns (Cloudflare DDNS tool)
This is a script to use Cloudflare as DDNS.  
This works on Linux only.

## How to use

### 1. Get a Cloudflare Zone ID and a Service key
Access your Cloudflare dashboard of your domain.  
On "API" section, you can find "Zone ID".  
Next, access [API Tokens page](https://dash.cloudflare.com/profile/api-tokens), and create new API Token.  
You should grant permissions "Zone/DNS/Read" and "Zone/DNS/Edit".  
Also, you should add your domain to "Zone Resources".  
I recommend select "Include/Specific zone/[domain]" because token is saved on the text file.  

### 2. Edit configuration file
The configuration file format is written below.

### 3. Execute cfddns
You should install Python 3 to execute cfddns.  
You can execute cfddns with command line, but I recommend use systemd.  
The example is written below.

## Configuration file format
```
# cfddns config                                 
zone_id=[Zone ID]
service_key=[API Token]
domains=[a.example.com],[b.example.com]
ipv6=[yes/no]
```

## Example of systemd unit file
```
[Unit]
Description = Cloudflare DDNS Service

[Service]
ExecStart = /usr/local/sbin/cfddns
Restart = always
Type = simple
StandardOutput = journal
StandardError = journal

[Install]
WantedBy = multi-user.target
```

## Known issues
- If domain is not A or AAAA record, cfddns will crash.
- If record has other records (ex. MX, TXT) as same name, cfddns will crash.
- Is is not able to set both A and AAAA record.
- Only one zone can be set.
- Configuration file format is too strict.
