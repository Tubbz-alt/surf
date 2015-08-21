//-----------------------------------------------------------------------------
// File          : AtcaDemoBoard.cpp
// Author        : Uros Legat <ulegat@slac.stanford.edu>
// Created       : 7/10/2015
// Project       : HPS carrier board and LLRF demo board
//-----------------------------------------------------------------------------
// Description :
// Device container for jesd, ADC, DAC, LMK 
//-----------------------------------------------------------------------------
// Copyright (c) 2013 by SLAC. All rights reserved.
// Proprietary and confidential to SLAC.
//-----------------------------------------------------------------------------
// Modification history :
// 11/14/2013: created
//-----------------------------------------------------------------------------
#include <AtcaDemoBoard.h>
#include <AxiVersion.h>
#include <Pgp2bAxi.h>
#include <JesdRxDaq.h>
#include <JesdRx.h>
#include <JesdTx.h>
#include <JesdTxGen.h>
#include <SigGenRam.h>

#include <Adc16Dx370.h>
#include <Dac38J84.h>
#include <Lmk04828.h>

#include <AxiMicronP30.h>
#include <Register.h>
#include <RegisterLink.h>
#include <Variable.h>
#include <Command.h>
#include <sstream>
#include <iostream>
#include <string>
#include <iomanip>
using namespace std;

// Constructor
AtcaDemoBoard::AtcaDemoBoard ( uint linkConfig, uint baseAddress, uint index, Device *parent, uint addrSize) : 
                        Device(linkConfig,baseAddress,"AtcaDemoBoard",index,parent) {
   
   Command      *c;
   powerUp = false;

   // Description
   desc_ = "LLRF demo Board";

   addDevice(new Pgp2bAxi   ( linkConfig, baseAddress | ((0x01000000>>2) * (addrSize)), 0, this, addrSize)); 
   addDevice(new AxiVersion ( linkConfig, baseAddress | ((0x00000000>>2) * (addrSize)), 0, this, addrSize));
   addDevice(new JesdRx     ( linkConfig, baseAddress | ((0x00100000>>2) * (addrSize)), 0, this, addrSize)); 
   addDevice(new JesdTx     ( linkConfig, baseAddress | ((0x00200000>>2) * (addrSize)), 0, this, addrSize));
   addDevice(new JesdRxDaq  ( linkConfig, baseAddress | ((0x00300000>>2) * (addrSize)), 0, this, addrSize));
  
   addDevice(new JesdTxGen  ( linkConfig, baseAddress | ((0x00400000>>2) * (addrSize)), 0, this, addrSize));
   addDevice(new SigGenRam  ( linkConfig, baseAddress | ((0x00410000>>2) * (addrSize)), 0, this, addrSize));
   addDevice(new SigGenRam  ( linkConfig, baseAddress | ((0x00420000>>2) * (addrSize)), 1, this, addrSize));
   
   addDevice(new Adc16Dx370 ( linkConfig, baseAddress | ((0x00500000>>2) * (addrSize)), 0, this, addrSize));
   addDevice(new Adc16Dx370 ( linkConfig, baseAddress | ((0x00600000>>2) * (addrSize)), 1, this, addrSize));
   addDevice(new Adc16Dx370 ( linkConfig, baseAddress | ((0x00700000>>2) * (addrSize)), 2, this, addrSize));
   
   addDevice(new Lmk04828   ( linkConfig, baseAddress | ((0x00800000>>2) * (addrSize)), 0, this, addrSize));
   addDevice(new Dac38J84   ( linkConfig, baseAddress | ((0x00900000>>2) * (addrSize)), 0, this, addrSize));
    
   getVariable("Enabled")->setHidden(true);
   
   // Variables
   getVariable("Enabled")->setHidden(true);
   
   //Commands
   addCommand(c = new Command("TurnSysrefOff"));
   c->setDescription("Powerdown the sysref lines.");
   
   addCommand(c = new Command("TurnSysrefOn"));
   c->setDescription("Powerup the sysref lines.");
   
}

// Deconstructor
AtcaDemoBoard::~AtcaDemoBoard ( ) { }

//! Method to process a command
 void AtcaDemoBoard::command ( string name, string arg) {
   if (name == "TurnSysrefOff") syarefOff();
   else if (name == "TurnSysrefOn") syarefOn();
   else Device::command(name,arg);
}
 
//! Powerdown the sysref lines.
void AtcaDemoBoard::syarefOff () {

   Register *r;

   REGISTER_LOCK
   
   //! Disable sysref in ADCs
   r = device("Adc16Dx370", 0) -> getRegister("AdcReg0x0012");
   r->set(0x0,2,0x1);
   writeRegister(r, true);   
   r = device("Adc16Dx370", 1) -> getRegister("AdcReg0x0012");
   r->set(0x0,2,0x1);
   writeRegister(r, true);
   r = device("Adc16Dx370", 2) -> getRegister("AdcReg0x0012");
   r->set(0x0,2,0x1);
   writeRegister(r, true); 
   
   
   //! Turn off sysref in LMK  
   r = device("Lmk04828", 0) -> getRegister("LmkReg0139");
   r->set(0x0,0,0x3);
   writeRegister(r, true);
      
   REGISTER_UNLOCK

}

//! Powerup the sysref lines.
void AtcaDemoBoard::syarefOn () {

   Register *r;
   
   REGISTER_LOCK
   
   //! Enable sysref in ADCs
   r = device("Adc16Dx370", 0) -> getRegister("AdcReg0x0012");
   r->set(0x1,2,0x1);
   writeRegister(r, true);   
   r = device("Adc16Dx370", 1) -> getRegister("AdcReg0x0012");
   r->set(0x1,2,0x1);
   writeRegister(r, true);
   r = device("Adc16Dx370", 2) -> getRegister("AdcReg0x0012");
   r->set(0x1,2,0x1);
   writeRegister(r, true);
   
   r = device("Lmk04828", 0) -> getRegister("LmkReg0139");
   r->set(0x3,0,0x3);
   writeRegister(r, true);
     
   REGISTER_UNLOCK
}


 
// // Method to read status registers and update variables
// void AtcaDemoBoard::readStatus ( ) {
//      // Sub devices
//    Device::readStatus();
// }

// void AtcaDemoBoard::readConfig ( ) {
//    // Sub devices
//    Device::readConfig();
// }


 

// Method to write configuration registers
void AtcaDemoBoard::writeConfig ( bool force ) {
   
   Register *r;  
      
   // Write sub devices  
   device("AxiVersion", 0) -> writeConfig(force);
   device("Pgp2bAxi", 0) -> writeConfig(force);
   device("Lmk04828", 0) -> writeConfig(force);
       
   device("JesdTx", 0) -> writeConfig(force);
   device("Adc16Dx370", 0) -> writeConfig(force);
   device("Adc16Dx370", 1) -> writeConfig(force);
   device("Adc16Dx370", 2) -> writeConfig(force);
   device("Dac38J84", 0)   -> writeConfig(force);
   
   // Set sysref delay before enableing RX
   REGISTER_LOCK
   r = device("JesdRx", 0) -> getRegister("SysrefDelay");
   r->set(0xb,0,0xff);
   writeRegister(r, true);
   REGISTER_UNLOCK
   
   device("JesdRx", 0)     -> writeConfig(force);
   device("JesdRxDaq", 0)  -> writeConfig(force);
   device("SigGenRam", 0)  -> writeConfig(force);
   device("SigGenRam", 1)  -> writeConfig(force);
   device("JesdTxGen", 0)  -> writeConfig(force);
   
   if (powerUp == true){ 
      // Synchronise internal counters at powerup
      
      printf("\n---------------Syncing LMK counters on powerup-------------\n");
      
      REGISTER_LOCK
      
      // Turn on normal SYNC
      r = device("Lmk04828", 0) -> getRegister("LmkReg0139");
      r->set(0x0,0,0x3);
      writeRegister(r, true);
      
      // Poweron SYNC
      r = device("Lmk04828", 0) -> getRegister("LmkReg0144");
      r->set(0x0,0,0xff);
      writeRegister(r, true);
      
      sleep(1);
      
      // Toggle Sync bit
      r = device("Lmk04828", 0) -> getRegister("LmkReg0143");
      r->set(0x1,5,0x1);
      writeRegister(r, true);
      r = device("Lmk04828", 0) -> getRegister("LmkReg0143");
      r->set(0x0,5,0x1);
      writeRegister(r, true);
      
      sleep(1);
      
      // Turn on normal continuous sysref
      r = device("Lmk04828", 0) -> getRegister("LmkReg0139");
      r->set(0x3,0,0x3);
      writeRegister(r, true);
      
      // Poweron down SYNC to not let it interfere
      r = device("Lmk04828", 0) -> getRegister("LmkReg0144");
      r->set(0xff,0,0xff);
      writeRegister(r, true);
      
      REGISTER_UNLOCK
      
      printf("\n---------------Syncing LMK counters on powerup-------------\n");
      
      // Put powerup to zero so this SYNC process will not be repeated
      // during the following writeConfig calls.
      // Soft reset will powerUp = false, after powerup execute SoftReset to 
      // Synchronise the counters
      powerUp = false;
   }
   
}

void AtcaDemoBoard::softReset() {
   powerUp = true;
   Device::softReset();
}

void AtcaDemoBoard::hardReset() {
   powerUp = true;
   Device::hardReset();
}