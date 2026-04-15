#!/usr/bin/env node
// Validates parity-manifest.json structure. Phase 2+ will extend this to
// compare the manifest against a snapshot of @mastra/client-js public methods.

import { readFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const manifestPath = resolve(here, '..', 'parity-manifest.json');
const manifest = JSON.parse(readFileSync(manifestPath, 'utf8'));

const errors = [];

function require(condition, message) { if (!condition) errors.push(message); }

require(manifest.upstream?.repository, 'upstream.repository missing');
require(manifest.upstream?.npmVersion, 'upstream.npmVersion missing');
require(manifest.upstream?.gitCommit, 'upstream.gitCommit missing');
require(manifest.resources && typeof manifest.resources === 'object', 'resources missing or not an object');
require(Array.isArray(manifest.exceptions), 'exceptions must be an array');

for (const ex of manifest.exceptions ?? []) {
    require(ex.jsSymbol, `exception missing jsSymbol: ${JSON.stringify(ex)}`);
    require(ex.reason, `exception missing reason: ${JSON.stringify(ex)}`);
}

for (const [resourceName, resource] of Object.entries(manifest.resources ?? {})) {
    require(resource.swiftType, `${resourceName} missing swiftType`);
    for (const [methodName, mapping] of Object.entries(resource.methods ?? {})) {
        require(mapping.swift, `${resourceName}.${methodName} missing swift mapping`);
        require(typeof mapping.phase === 'number', `${resourceName}.${methodName} missing phase`);
    }
}

if (errors.length) {
    console.error('Parity manifest validation failed:');
    for (const err of errors) console.error(' -', err);
    process.exit(1);
}
console.log('Parity manifest OK');
