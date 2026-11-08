import navigation from './src/data/guide-navigation.json' with {type:'json'};

const taskCategory = (id,label) => {
  const platform=navigation.platforms.find(item=>item.id===id);
  return {type:'category',label,link:{type:'doc',id:`platforms/${id}`},collapsed:true,
    items:platform.topics.map(topic=>`platforms/${id}/${topic.id}`)};
};
export default {
  guide: [
    'start',
    {type:'category',label:'Platform guides',link:{type:'doc',id:'platforms'},items:[
      {...taskCategory('macos','Mac'),items:[...taskCategory('macos','Mac').items,taskCategory('macos-cli','Command line (CLI) — Mac')]},
      taskCategory('ios','iPhone'),
      taskCategory('ipad','iPad'),
      {type:'category',label:'Android',collapsed:true,items:[taskCategory('android','Android phone'),taskCategory('android-tablet','Android tablet')]},
      {...taskCategory('linux','Linux'),items:[...taskCategory('linux','Linux').items,taskCategory('linux-cli','Command line (CLI) — Linux')]},
      {...taskCategory('windows','Windows'),items:[...taskCategory('windows','Windows').items,taskCategory('windows-cli','Command line (CLI) — Windows')]},
    ]},
    {type:'category',label:'Concepts and shared guidance',collapsed:true,items:['moldsign','signing','browser','troubleshooting']},
  ],
};
