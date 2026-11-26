// Import first in a test file: lets Node load the site's JSX components with test stand-ins.
import {register} from 'node:module';

register('./hooks.mjs', import.meta.url);
