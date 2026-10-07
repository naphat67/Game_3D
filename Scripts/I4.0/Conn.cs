using Godot;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using System.IO;
using Newtonsoft.Json;
using TAO71.I4_0;
using FileAccess = Godot.FileAccess;

public partial class Conn : Node
{
	// Scripts
	private static Resource Globals = ResourceLoader.Load("res://Scripts/Globals.gd");
	
	// Configuration and socket
	private static ClientConfiguration? Config = null;
	private static ClientSocket? Socket = null;
	public const string ConfigPath = "user://I4.0_config.json";
	
	// Other
	[Export] public Control ErrorContainer;
	
	private static Dictionary<string, object> ParseTool(Dictionary<string, object> Tool)
	{
		return new Dictionary<string, object>() {
			{"type", "function"},
			{"function", new Dictionary<string, object>() {
				{"name", Tool["name"]},
				{"description", Tool["description"]},
				{"parameters", new Dictionary<string, object>() {
					{"type", "object"},
					{"properties", Tool["parameters"]},
					{"required", Tool["required"]}
				}}
			}}
		};
	}

	private static async Task ConnectToServer(List<string> Models)
	{
		bool modelFound = false;

		if (Socket.IsConnected())
		{
			foreach (string model in await Socket.GetAvailableModels())
			{
				if (Models.Contains(model))
				{
					modelFound = true;
					break;
				}
			}
			
			if (modelFound)
			{
				return;
			}
		}

		foreach (string server in (string[])Globals.Get("Instance").AsGodotObject().Get("I4_Servers"))
		{
			try
			{
				GD.Print($"Connecting to {server}");

				string srv = server;
				int port = 8060;

				if (server.Contains(':'))
				{
					port = int.Parse(server.Substring(server.Find(':') + 1));
					srv = server.Substring(0, server.Find(':'));
				}

				try
				{
					await Socket.Connect(srv, port, true);
				}
				catch
				{
					await Socket.Connect(srv, port, false);
				}

				GD.Print($"Finding {Models}");

				foreach (string model in await Socket.GetAvailableModels())
				{
					if (Models.Contains(model))
					{
						modelFound = true;
						break;
					}
				}

				if (modelFound)
				{
					break;
				}
			}
			catch (Exception ex)
			{
				GD.PushWarning($"Could not connect to server {server}: {ex}");
				continue;
			}
		}

		if (!modelFound)
		{
			GD.PushError("Could not connect to server of find any of the models.");
		}
	}

	public override async void _Ready()
	{
		Globals.Call("CheckInstance");

		if (Config == null)
		{
			if (FileAccess.FileExists(ConfigPath))
			{
				FileAccess file = FileAccess.Open(ConfigPath, FileAccess.ModeFlags.Read);
				Config = ClientConfiguration.FromDict(JsonConvert.DeserializeObject<Dictionary<string, object?>>(file.GetAsText()));
			}
			else
			{
				FileAccess file = FileAccess.Open(ConfigPath, FileAccess.ModeFlags.Write);
				file.StoreString(JsonConvert.SerializeObject(Config.ToDict(false)));
			}
		}

		if (Socket == null)
		{
			Socket = new ClientSocket("websocket", Config!);
		}
	}

	public override void _Process(double Delta)
	{
	}
}
