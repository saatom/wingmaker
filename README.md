# wingmaker
Wyatt Richards <wr1701@proton.me>

Disclaimer: This project is far from complete; IT WILL BE A BUGGY MESS! Please don't expect a polished product just yet.

Octave script(s) for analyzing custom wing configurations and producing laser cutter files to produce relevant ribs and spars. Currently supports general wing geometry creation with performance anlysis through XFOIL.

This system uses Octave structs to contain data (I am using structs much like you'd use objects in OOP languages). See the sampleconfig.csv file for an example wing configuration but the basic principle is that airfoil sections are specified all throughout the wing, allowing for complex geometry that would be tedious to produce by hand.


<img width="3189" height="1291" alt="Screenshot_20250901_161211" src="https://github.com/user-attachments/assets/ab128184-0660-4e88-aeb9-8c229752f2a4" />

Performance analysis is done through XFOIL. Please note that due to the way I programmed the system calls, this aspect will likely only work on Linux systems with a global environment variable for XFOIL. Also, please avoid using the flatpak version of Octave because I've had issues with it not recognizing certain parts of my filesystem; your mileage may vary. I am running the latest version of Octave which is built from source and using fltk graphics engine.
Please don't hesitate to email me with any questions or suggestions.
