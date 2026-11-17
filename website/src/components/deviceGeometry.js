// iPhone outline/screen ratio from Apple's official iPhone 17 Pro Max product resource:
// 1470 × 3000 outline; screen opening at (75, 66), 1320 × 2868.
// Only dimensions are used here; the licensed product PNG is not redistributed.
export const iphone = {
  frame: {x:170,y:30,width:294,height:600,rx:34},
  screen: {x:185,y:43.2,width:264,height:573.6,rx:22},
  port: {x:317,y:630},
};
// Generic Android handset. Native 1080 × 2400 capture retains its 9:20 screen ratio.
export const androidPhone = {
  frame: {x:170,y:30,width:286,height:610,rx:30},
  screen: {x:181,y:41,width:264,height:586.6667,rx:21},
  port: {x:313,y:640},
  openingScreenFraction: .90,
  screenWidthFraction: .80,
};
// Generic 16:9 desktop display. App windows are contained, never stretched to fill it.
export const desktop = {
  frame: {x:120,y:25,width:860,height:500,rx:18},
  screen: {x:130,y:35,width:840,height:472.5,rx:9},
  port: {x:980,y:480},
};
