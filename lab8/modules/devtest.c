#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include "sound.h"

//From xac97.h
#define AC97_VOL_MUTE     0x8000
#define AC97_VOL_MIN      0x1f1f
#define AC97_VOL_MID      0x0a0a
#define AC97_VOL_MAX      0x0000

// PCM Data rate constants
// AC97_PCM_DAC_Rate       0x2C
// AC97_PCM_ADC_Rate       0x32
#define AC97_PCM_RATE_8000_HZ  0x1F40
#define AC97_PCM_RATE_11025_HZ 0x2B11
#define AC97_PCM_RATE_16000_HZ 0x3E80
#define AC97_PCM_RATE_22050_HZ 0x5622
#define AC97_PCM_RATE_44100_HZ 0xAC44
#define AC97_PCM_RATE_48000_HZ 0xBB80

/*
A simple print function to print out what the command is
doing so the user knows what to expect from the entered
command. 
*/
void print(char c, int cmd) {
	if(c == 's')
		switch(cmd) {
			case AC97_VOL_MUTE:
				printf("Command: Mute Volume\n");
				break;
			case AC97_VOL_MIN:
				printf("Command: Minimum Volume\n");
				break;
			case AC97_VOL_MID:
				printf("Command: Medium Volume\n");
				break;
			case AC97_VOL_MAX:
				printf("Command: Maximum Volume\n");
				break;
			default:
				printf("Command: Unknown\n");
				break;
		}
	else if(c == 'p')
		switch(cmd) {
			case AC97_PCM_RATE_8000_HZ:
				printf("Command: Play rate 8000Hz (Slow) \n");
				break;
			case AC97_PCM_RATE_11025_HZ:
				printf("Command: Play rate 11025Hz (Normal) \n");
				break;
			case AC97_PCM_RATE_16000_HZ:
				printf("Command: Play rate 16000Hz (Fast) \n");
				break;
			case AC97_PCM_RATE_22050_HZ:
				printf("Command: Play rate 22050Hz (Faster) \n");
				break;
			case AC97_PCM_RATE_44100_HZ:
				printf("Command: Play rate 44100Hz (Fasterer) \n");
				break;
			case AC97_PCM_RATE_48000_HZ:
				printf("Command: Play rate 48000Hz (Fastest) \n");
				break;
		}

}

int main()
{
  int fd;
  char input = 0;

  //Array of sound controls
  int sound[4] = {AC97_VOL_MUTE, AC97_VOL_MIN, AC97_VOL_MID, AC97_VOL_MAX};
  //Pointer to sound array for the ioctl function
  int* sound_ptr = sound;

  //Array of playback controls
  int playback[6] = {AC97_PCM_RATE_8000_HZ, AC97_PCM_RATE_11025_HZ, AC97_PCM_RATE_16000_HZ, AC97_PCM_RATE_22050_HZ, AC97_PCM_RATE_44100_HZ, AC97_PCM_RATE_48000_HZ};
  //Pointer to playback array for the ioctl function
  int* pb_ptr = playback;

  /* open device file for reading and writing */
  /* use "open" to open '/dev/xac97' */
  fd = open("/dev/xac97", O_RDWR);

  /* handle error opening file */
  if(fd == -1)
  {
    printf("Failed to open device file!\n");
    return -1;
  }

  /*
	We will iterate through the arrays depending on which
	option was selected (s or p) and execute each command
	in the array.
  */
  printf("Enter a command (s - volume control, p - playback control): ");
	input = getchar();
  while( input != 'q'){
	  if(input == 's') { //Sound commands
			  ioctl(fd, ADJUST_AUX_VOL, sound_ptr);
			  print('s', *sound_ptr); //Print out the command
			  sound_ptr++;
			  if(sound_ptr == (sound+4)) //If the pointer hit the end of the array, reset it to the first cell
				  sound_ptr = sound;
	  }
	  if(input == 'p') { //Playback commands
			  ioctl(fd, ADJUST_PLAYBACK_RATE, pb_ptr);
			  print('p', *pb_ptr); //Print out the command
			  pb_ptr++;
			  if(pb_ptr == (playback+6)) //Same pointer logic as before, reset if it hit the end
				  pb_ptr = playback; 
	  }
	printf("Enter command: ");
	input = getchar();
  }
  close(fd);
  return 0;

}
