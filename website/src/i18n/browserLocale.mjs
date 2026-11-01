export function browserLocale(languages){
 return languages.map(value=>value.toLowerCase().split('-')[0]).find(value=>['en','ro','ru'].includes(value)) || 'en';
}
