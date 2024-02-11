#!/usr/bin/env python3
"""
cfddns v1.0

Copyright (c) 2022-2023 Awayume

Released under the MIT license.
see https://opensource.org/licenses/MIT
"""

from __future__ import annotations

from typing import Optional, TypedDict, TypeVar

import json
import logging
import subprocess
import sys
import time
import traceback

import requests
from systemd import journal

T = TypeVar('T', bound=dict)
U = TypeVar('U', bound=dict)

logger = logging.getLogger('cfddns')
logger.addHandler(journal.JournalHandler())
logger.setLevel(logging.INFO)

class Config(TypedDict):
    zone_id: Optional[str]
    service_key: Optional[str]
    domains: list[Optional[str]]
    ipv6: Optional[bool]

class RecordPayload(TypedDict):
    type: Optional[str]
    name: Optional[str]
    content: str
    ttl: int
    proxied: Optional[bool]

config: Config = {
        'zone_id': None,
        'service_key': None,
        'domains': [],
        'ipv6': False
    }

def get_config() -> None:
    logger.debug('Loading cfddns configuration...')
    cfg_file: str = '/etc/cfddns/cfddns.conf'
    with open(cfg_file, mode='r') as f:
        lines: list[str] = f.readlines()
        for line in lines:
            line = line.replace(' ', '')
            if line.startswith('zone_id'):
                config['zone_id'] = line.replace('zone_id=', '').strip()
                logger.debug('Cloudflare zone ID set.')
            elif line.startswith('service_key'):
                config['service_key'] = 'Bearer ' + line.replace('service_key=', '').strip()
                logger.debug('Cloudflare service key set.')
            elif line.startswith('domains'):
                config['domains'] = line.replace('domains=', '').strip().split(',')
                logger.debug('Domains to monitor set.')
            elif line.startswith('ipv6'):
                config['ipv6'] = True if line.replace('ipv6=', '') == 'yes' else False
                logger.debug('IPv6 mode enabled.')
    logger.info('cfddns configuration loaded.')

def get_global_ip() -> str:
    logger.debug('Getting global IP address...')
    logger.debug('Running dig...')
    process: subprocess.CompletedProcess
    process = subprocess.run(['dig',
            '-6' if config['ipv6'] else '-4',
            '@one.one.one.one',
            'whoami.cloudflare',
            'TXT', 'CH', '+short'],
            encoding='utf-8',
            stdout=subprocess.PIPE)
    global_ip: str = process.stdout.replace('"', '').strip()
    logger.debug('Completed running dig.')
    logger.debug('Completed getting global IP address.')
    logger.debug('Global IP address is ' + global_ip)
    return global_ip

def get_current_dns() -> T:
    logger.debug('Getting current DNS records.. ')
    dns_api_url: str = f'https://api.cloudflare.com/client/v4/zones/{config["zone_id"]}/dns_records'
    headers: dict[str, str] = {'Authorization': config['service_key'], 'Content-Type': 'application/json'}
    logger.debug('Sending API request...')
    response: requests.models.Response = requests.get(dns_api_url, headers=headers)
    logger.debug('Completed sending API request.')
    if response.status_code == 200:
        logger.debug('Status code that Cloudflare API returned is 200.')
        logger.debug('Completed getting current DNS records.')
        return response.json()
    else:
        logger.error('Status code that Cloudflare API returned is ' + response.status_code)
        logger.error(response.text)
        raise RuntimeError('Failed to API request')

def set_correct_record(global_ip: str, incorrect_records: list[U]) -> None:
    logger.info('Setting correct DNS records...')
    logger.info('Global IP address is ' + global_ip)
    dns_api_url_base: str = f'https://api.cloudflare.com/client/v4/zones/{config["zone_id"]}/dns_records/'
    headers: dict[str, str] = {'Authorization': config['service_key'], 'Content-Type': 'application/json'}
    payload: RecordPayload = {'type': None, 'name': None, 'content': global_ip, 'ttl': 1, 'proxied': None}
    for record in incorrect_records:
        logger.info(f'Setting correct DNS record for {record["name"]}...')
        payload['type'] = record['type']
        payload['name'] = record['name']
        payload['proxied'] = record['proxied']
        logger.debug('Sending API request...')
        response: requests.models.Response = requests.put(dns_api_url_base + record['id'], data=json.dumps(payload), headers=headers)
        logger.debug('Completed sending API request.')
        if response.status_code != 200:
            logger.error('Status code that Cloudflare API returned is ' + response.status_code)
            logger.error(response.text)
            raise RuntimeError('Failed to API request')
        logger.info('Completed setting correct DNS records.')

def check_current_dns() -> None:
    logger.debug('Checking current DNS records...')
    global_ip: str = get_global_ip()
    records: T = get_current_dns()
    incorrect_records: list[U] = []
    for record in records['result']:
        if not record['type'] in ['A', 'AAAA']:
            continue
        elif record['name'] in config['domains']:
            logger.debug('Found a record to monitor: ' + record['name'])
            if record['content'] != global_ip:
                logger.info('Found an incorrect DNS record, content is ' + record['content'])
                incorrect_records.append(record)
    if len(incorrect_records) != 0:
        logger.info('Detected incorrect DNS records.')
        set_correct_record(global_ip, incorrect_records)
    else:
        logger.debug('No incorrect DNS records.')
    logger.debug('Completed checking current DNS records.')

def main() -> None:
    logger.info('cfddns started.')
    get_config()
    while True:
        check_current_dns()
        time.sleep(60)

if __name__ == '__main__':
    try:
        main()
    except Exception:
        logger.error('An Error raised:\n' + traceback.format_exc())
        time.sleep(300)
