# VHS Tape — 山夏摄影约拍 Demo GIF
# 安装 vhs: https://github.com/charmbracelet/vhs
# 录制: vhs assets/demo.tape
# 要求: 在 skill 根目录运行

Output assets/demo.gif
Set FontSize 16
Set Width 800
Set Height 600
Set TypingSpeed 50ms

Type "python3 scripts/consult.py --type 写真"
Sleep 500ms
Enter
Sleep 2s

Type "python3 scripts/consult.py --type 写真 --student"
Sleep 500ms  
Enter
Sleep 2s

Type "python3 scripts/consult.py --type 婚礼跟拍"
Sleep 500ms
Enter
Sleep 2s

Type "python3 scripts/consult.py --type 写真 --budget 100"
Sleep 500ms
Enter
Sleep 3s
