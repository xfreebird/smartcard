export const previewPlatforms=['auto','macos','windows','linux','iphone','android'];

export function debugPreviewEnabled(hostname,development=false){
 return development || ['localhost','127.0.0.1','::1','[::1]'].includes(hostname);
}

export function previewChoice(value){
 return previewPlatforms.includes(value)?value:'auto';
}

export function storyPlatform(choice,userAgent,width){
 if(previewChoice(choice)!=='auto')return choice;
 if(/Android/i.test(userAgent))return 'android';
 if(/iPhone|iPad|iPod/i.test(userAgent) || width<=760)return 'iphone';
 if(/Windows/i.test(userAgent))return 'windows';
 if(/Linux/i.test(userAgent))return 'linux';
 return 'macos';
}
