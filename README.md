# StandPad

Enable StandBy feature on iPadOS.

Only for developers at the moment.

Known Issue : Widgets are not showing.

![](0.png)

## How to turn on StandBy

```
(lldb) po [[[[[UIApplication sharedApplication] connectedScenes] firstObject] ambientPresentationController] _setPresented:0x1]
```
