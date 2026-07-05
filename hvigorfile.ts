import { appTasks } from '@ohos/hvigor-ohos-plugin';
import { localSigningPlugin } from './hvigor/local-signing-plugin';

export default {
  system: appTasks, /* Built-in plugin of Hvigor. It cannot be modified. */
  plugins: [
    localSigningPlugin()
  ]
}
