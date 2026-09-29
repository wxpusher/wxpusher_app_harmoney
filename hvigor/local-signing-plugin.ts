import type { HvigorNode, HvigorPlugin } from '@ohos/hvigor';
import { OhosPluginId } from '@ohos/hvigor-ohos-plugin';
import type { OhosAppContext } from '@ohos/hvigor-ohos-plugin';
import * as fs from 'fs';
import * as os from 'os';
import * as path from 'path';

interface SigningMaterial {
  storeFile: string;
  storePassword: string;
  keyAlias: string;
  keyPassword: string;
  signAlg: string;
  profile: string;
  certpath: string;
}

const LOCAL_PRODUCT = 'default';
const LOCAL_SIGNING_CONFIG = 'default';
const SIGNING_CONFIG_ENV = 'WXPUSHER_HARMONY_SIGNING_CONFIG';
const DEFAULT_SIGNING_CONFIG_PATH = path.join(
  os.homedir(),
  '.ohos',
  'wxpusher-app-harmony-signing.json'
);

function requireString(
  material: Partial<SigningMaterial>,
  field: keyof SigningMaterial,
  configPath: string
): string {
  const value = material[field];
  if (typeof value !== 'string' || value.length === 0) {
    throw new Error(`Missing "${field}" in local signing config: ${configPath}`);
  }
  return value;
}

function loadSigningMaterial(configPath: string): SigningMaterial | undefined {
  if (!fs.existsSync(configPath)) {
    return undefined;
  }

  let parsed: Partial<SigningMaterial>;
  try {
    parsed = JSON.parse(fs.readFileSync(configPath, 'utf8')) as Partial<SigningMaterial>;
  } catch (error) {
    throw new Error(`Unable to parse local signing config ${configPath}: ${String(error)}`);
  }

  const material: SigningMaterial = {
    storeFile: requireString(parsed, 'storeFile', configPath),
    storePassword: requireString(parsed, 'storePassword', configPath),
    keyAlias: requireString(parsed, 'keyAlias', configPath),
    keyPassword: requireString(parsed, 'keyPassword', configPath),
    signAlg: requireString(parsed, 'signAlg', configPath),
    profile: requireString(parsed, 'profile', configPath),
    certpath: requireString(parsed, 'certpath', configPath)
  };

  for (const fileField of ['storeFile', 'profile', 'certpath'] as const) {
    if (!fs.existsSync(material[fileField])) {
      throw new Error(
        `Local signing file "${fileField}" does not exist: ${material[fileField]}`
      );
    }
  }

  return material;
}

export function localSigningPlugin(): HvigorPlugin {
  return {
    pluginId: 'wxpusher.local-signing',
    apply(node: HvigorNode): void {
      const context = node.getContext(OhosPluginId.OHOS_APP_PLUGIN) as
        OhosAppContext | undefined;
      if (!context || context.getCurrentProduct().getProductName() !== LOCAL_PRODUCT) {
        return;
      }

      const configPath = process.env[SIGNING_CONFIG_ENV]?.trim()
        || DEFAULT_SIGNING_CONFIG_PATH;
      const material = loadSigningMaterial(configPath);
      if (!material) {
        return;
      }

      const profile = context.getBuildProfileOpt();
      const signingConfigs = profile.app.signingConfigs ?? [];
      profile.app.signingConfigs = signingConfigs.map((config) => {
        if (config.name !== LOCAL_SIGNING_CONFIG) {
          return config;
        }
        return {
          ...config,
          type: 'HarmonyOS',
          material
        };
      });
      context.setBuildProfileOpt(profile);
    }
  };
}
