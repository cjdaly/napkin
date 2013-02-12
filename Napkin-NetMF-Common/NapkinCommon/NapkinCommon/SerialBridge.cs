using System;
using System.IO.Ports;
using System.Collections;
using Microsoft.SPOT;

namespace NapkinCommon
{

    public class SerialBridge : ThreadedSerialDevice
    {
        public SerialBridge(string serialPortName = Serial.COM1)
            : base(serialPortName)
        {
        }

        private Hashtable _commandTable = new Hashtable();
        private ArrayList _commandList = new ArrayList();

        private void AddCommand(SerialBridgeCommand command)
        {
            command._serialBridge = this;
            _commandTable.Add(command.Name, command);
            _commandList.Add(command);
        }

    }

    //public class SerialBridgeServer : SerialBridge
    //{
    //}

    //public class SerialBridgeClient : SerialBridge
    //{
    //}


    public abstract class SerialBridgeCommand
    {
        internal SerialBridge _serialBridge;

        public SerialBridgeCommand(string name, string description)
        {
            _name = name;
            _description = description;
        }

        private string _name;
        public string Name { get { return _name; } }

        private string _description;
        public string Description { get { return _description; } }

        public abstract void InvokeOnHost();
        public abstract void InvokeOnClient();

    }

    public class PingCommand : SerialBridgeCommand
    {
        public PingCommand() : base("ping", "Client replies with 'pong'.")
        {
        }

        public override void InvokeOnHost()
        {
            _serialBridge.WriteLine(Name);
        }

        public override void InvokeOnClient()
        {
            _serialBridge.WriteLine("pong");
        }
    }

    public class HelpCommand : SerialBridgeCommand
    {
        public HelpCommand() : base("help", "List supported commands.")
        {
        }

        public override void InvokeOnHost()
        {
            // feed the read buffer directly?
        }

        public override void InvokeOnClient()
        {
            // not sent to client
        }
    }

}

