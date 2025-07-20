# wingmaker
CREATED BY: Wyatt Richards
EMAIL: wr1701@proton.me

Octave script(s) for analyzing custom wing configurations and producing laser cutter files to produce relevant ribs and spars. Currently supports general wing geometry creation with performance anlysis through XFOIL.

This system uses Octave structs to contain data (I am using structs much like you'd use objects in OOP languages). See the sampleconfig.csv file for an example wing configuration but the basic principle is that airfoil sections are specified all throughout the wing, allowing for complex geometry that would be tedious to produce by hand.
<img width="2367" height="837" alt="sample_wing" src="https://github.com/user-attachments/assets/a172225b-be39-4d17-bf19-f5cf60ec9d45" />
Performance analysis is done through XFOIL. Please note that due to the way I programmed the system calls, this aspect will likely only work on Linux systems with a global environment variable for XFOIL. Also, please avoid using the flatpak version of Octave because I've had issues with it not recognizing certain parts of my filesystem; your mileage may vary. I am running the latest version of Octave which is built from source and using fltk graphics engine.
<img width="2685" height="2094" alt="sample_graph" src="https://github.com/user-attachments/assets/63763502-f6f3-445c-b3fd-8319126e5d79" />
Please don't hesitate to email me with any questions or suggestions.
