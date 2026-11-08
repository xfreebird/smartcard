import React, {useState} from 'react';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import navigation from '@site/src/data/guide-navigation.json';

const copy = {
  en: {search:'Find a task',hint:'Search PDF, PIN, browser or Siri…',device:'Device',all:'All devices and interfaces',results:'Results',empty:'No matching task. Try another word or device.',app:'App guides',cli:'Command line (CLI)',reference:'Desktop reference'},
  ro: {search:'Găsește o activitate',hint:'Caută PDF, PIN, browser sau Siri…',device:'Dispozitiv',all:'Toate dispozitivele și interfețele',results:'Rezultate',empty:'Nicio activitate găsită. Încearcă alt cuvânt sau dispozitiv.',app:'Ghidurile aplicației',cli:'Linie de comandă (CLI)',reference:'Referință desktop'},
  ru: {search:'Найдите задачу',hint:'Ищите PDF, PIN, браузер или Siri…',device:'Устройство',all:'Все устройства и интерфейсы',results:'Результаты',empty:'Задача не найдена. Попробуйте другое слово или устройство.',app:'Руководства приложения',cli:'Командная строка (CLI)',reference:'Справочник приложения'},
};
const fold = text => text.normalize('NFKD').replace(/[\u0300-\u036f]/g,'').toLowerCase().replace(/пин/g,'pin');
const aliases = {signing:'PDF XML XAdES PAdES stamp ștampilă штамп',preferences:'PIN theme language limbă temă язык тема',automation:'Siri Spotlight Handoff Shortcuts Scurtături команды',unattended:'1Password Keychain env PIN credential',documents:'history istoric история files fișiere файлы',browser:'browser bookmark cookie site browser marcaje браузер закладки cookies'};

export default function GuideDirectory({platform}) {
  const {i18n} = useDocusaurusContext();
  const locale = copy[i18n.currentLocale] ? i18n.currentLocale : 'en';
  const labels = copy[locale];
  const [query,setQuery] = useState('');
  const [selected,setSelected] = useState('');
  const scope = platform || selected;
  const words = fold(query).trim().split(/\s+/).filter(Boolean);
  const topics = navigation.platforms.filter(item => !scope || item.id === scope).flatMap(item => item.topics.map(topic => ({platform:item,topic}))).filter(({platform:item,topic}) => {
    const text=fold([item.labels[locale],topic.labels[locale],topic.descriptions[locale],...topic.headings[locale],aliases[topic.id] || ''].join(' '));
    return words.every(word=>text.includes(word));
  });
  const showDevices = !scope && !words.length;
  return <div className="guide-directory">
    <div className="guide-directory-filters">
      <label>{labels.search}<input type="search" value={query} placeholder={labels.hint} onChange={event=>setQuery(event.target.value)} /></label>
      {!platform && <label>{labels.device}<select value={selected} onChange={event=>setSelected(event.target.value)}>
        <option value="">{labels.all}</option>
        {navigation.platforms.map(item=><option key={item.id} value={item.id}>{item.labels[locale]}</option>)}
      </select></label>}
    </div>
    {!showDevices && <p className="guide-directory-count" role="status">{labels.results}: {topics.length}</p>}
    {showDevices ? <div className="guide-directory-grid">{navigation.groups.map(group=><section key={group.id} className="guide-device-card">
      <h2>{group.labels[locale]}</h2>
      {group.platforms.map(id=>{
        const item=navigation.platforms.find(candidate=>candidate.id===id);
        const label=group.platforms.length===1 ? labels.app : item.kind==='cli' ? labels.cli : item.kind==='reference' ? labels.reference : item.labels[locale];
        const shortcuts=['setup','signing','verification'].map(topic=>item.topics.find(candidate=>candidate.id===topic)).filter(Boolean);
        return <div key={id} className="guide-device-option">
          <Link className="guide-device-overview" to={`/docs/platforms/${id}/`}>{label} →</Link>
          <ul>{shortcuts.map(topic=><li key={topic.id}><Link to={`/docs/platforms/${id}/${topic.id}/`}>{topic.labels[locale]}</Link></li>)}</ul>
        </div>;
      })}
    </section>)}</div> : topics.length ? <div className="guide-directory-grid">{topics.map(({platform:item,topic})=><Link key={`${item.id}/${topic.id}`} className="guide-task-card" to={`/docs/platforms/${item.id}/${topic.id}/`}>
      {!platform && <small>{item.labels[locale]}</small>}
      <h2>{topic.labels[locale]}</h2><p>{topic.descriptions[locale]}</p><span aria-hidden="true">→</span>
    </Link>)}</div> : <p>{labels.empty}</p>}
  </div>;
}
