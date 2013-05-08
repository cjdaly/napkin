﻿
//------------------------------------------------------------------------------
// <auto-generated>
//     This code was generated by the Gadgeteer Designer.
//
//     Changes to this file may cause incorrect behavior and will be lost if
//     the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------

using Gadgeteer;
using GTM = Gadgeteer.Modules;

namespace napkin.systems.gadgeteer.cerb2
{
    public partial class Program : Gadgeteer.Program
    {
        // GTM.Module definitions
        Gadgeteer.Modules.Seeed.Barometer barometer;
        Gadgeteer.Modules.GHIElectronics.Button button;
        Gadgeteer.Modules.GHIElectronics.LightSensor lightSensor;
        Gadgeteer.Modules.GHIElectronics.GasSense gasSense;

        public static void Main()
        {
            //Important to initialize the Mainboard first
            Mainboard = new GHIElectronics.Gadgeteer.FEZCerberus();			

            Program program = new Program();
            program.InitializeModules();
            program.ProgramStarted();
            program.Run(); // Starts Dispatcher
        }

        private void InitializeModules()
        {   
            // Initialize GTM.Modules and event handlers here.		
            barometer = new GTM.Seeed.Barometer(1);
		
            gasSense = new GTM.GHIElectronics.GasSense(2);
		
            button = new GTM.GHIElectronics.Button(3);
		
            lightSensor = new GTM.GHIElectronics.LightSensor(4);

        }
    }
}