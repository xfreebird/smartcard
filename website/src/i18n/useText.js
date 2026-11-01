import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import catalog from './catalog.json';
export default function useText(){
 const {i18n:{currentLocale}}=useDocusaurusContext();
 return key=>catalog[key]?.[currentLocale] ?? catalog[key]?.en ?? key;
}
