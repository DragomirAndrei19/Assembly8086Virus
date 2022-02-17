# Assembly8086Virus
Assembly 8086 virus (Modified CSpawn - companion virus for .com files)

Inspired by CSPAWN virus in Giant Black Book of Computer Viruses (page 48)

### #### IMPORTANT - THE VIRUS ONLY INFECTS .COM FILES (the predecessor of .exe files) on 16 bit CPU architectures  
### ####              should only be ran in controlled environments (ex: DOSBOX emulator)

### How to run
TASM virus.asm
TLINK virus.asm
virus.com

# Brief description of the virus


The INFECT_FILE routine was written to give the host a random name, and make it a hidden file. Furthermore, it makes the viral program visible, but it comes up with a strategy to avoid re-infection at the level of the FIND_FILES routine so that INFECT_FILE is never even called to infect something that should not be infected.

In order to modify how the infection is done, function 5AH from INT21h was used. This function creates an empty file with a random name of length 8. Instead of changing the infected file extension from .com to .con, hiding it and writing the virus into a new file named exactly as the file being infected (as the unmodified virus does), we rename the infected file with the name of the file created by function 5AH. Then we write the virus's code into the empty file created by 5AH and we rename this one to whatever the host was called before infection. To avoid reinfection, we compare the size of the host to be infected with the size of the virus (calculated dynamically). If they are the exact same size, it means it's already infected so we skip infection through INFECT_FILE routine. This is how reinfection is avoided.

EX: We have Host1.com and Virus.com. When ran, Virus.com creates a randomly named file (POERTY - no extension - 0KB). We rename Host1.com to POERTY.con and we hide it. Then we write the code of the virus into the empty POERTY file and rename it as Host1.com (to give the impression that it's the original file)

In the INFECT_FILE routine - First of all, we create an empty, randomly named file using function 5AH. After the function is executed, into AX we have the file handler (which we'll save into BX). We then save the random name in a buffer variable. We also add .con extension to that name saved in the buffer. Then we rename the host from whatever it was called before (this name is saved at offset 9EH after search for first match (4Eh) and search for next match (4Fh) functions are called.) to the random name + extension saved in the affordmentioned buffer variable. We rename the file using the function 56H. Then we clear the buffer zone where function 5AH returns the name of the created file, which is a random one. Finally, using function 40H we write the virus code into the empty file created by 5AH. After that, we rename this to what the infected file was called originally.

The host is also hidden using function AH=43 - > CHMOD - SET FILE ATTRIBUTES

EX: We have file H1.COM in a directory, which will be infected. Function 51A created a randomly named file (ex: IOUEKJZA - with no extension). We rename H1.COM to IOUEKJZA.con and hide it. Finally, we write the virus code into IOUEKJZA (without extension) and rename it to H1.COM.

Now H1.COM will be infected and when called, it will infect other .com files but will also do what it was doing before infection (because the original H1.COM file is now renamed to IOUEKJZA.con)

In the FIND_FILE routine - A procedure was built which tells the size of the file to be infected and saves it into BX. During the FIND_LOOP, when we are searching for .com files to infect, if we find any file the same size as the virus, we skip infection by immediately going to the next file that "search next" will find using JE (jump equal). For this we use CMP BX, (FINISH - CSpawn), where BX is the result of the procedure that tells us the size of the file to be infected and (FINISH - CSpawn) is the size of the virus.

# A brief description of each procedure.

TELL_SIZE is a procedure of type NEAR that puts into BX the size in bytes of the currently found .com file. According to INT21h documentation for functions 4Eh and 4Fh (search first/next), after the functions are done, the DTA is filled at bytes 26-27 with least significant word of file size and at bytes 28-29 with the most significant word of file size. DTA is at offset 80H, therefore the least significant word of filesize is always at offset 9AH whereas the most significant word is at offset 9CH. At the end of the procedure, we only need to store into BX the least significant word of file size because the file size of a .com file cannot exceed ~64 kb or a maximum of FF00h.
