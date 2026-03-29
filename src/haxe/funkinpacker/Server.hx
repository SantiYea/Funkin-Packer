package funkinpacker;

import haxe.atomic.AtomicBool;
import haxe.io.Bytes;
import haxe.io.Path;
import haxe.io.Mime;
import haxe.Resource;
import haxe.Exception;
import sys.io.File;
import sys.FileSystem;
import sys.net.Host;
import sys.net.Socket;
import sys.thread.Thread;

using StringTools;

@:nullSafety
class Server
{
	public static var DEFAULT_IP:String = '127.0.0.1';
	public static var DEFAULT_PORT:Int = 8000;
	public static var serverPort(default, null):Int = DEFAULT_PORT;
	public static var server:Null<Socket>;
	public static var running(default, null):AtomicBool = new AtomicBool(false);

	public static function startServer(root:String, ?port:Int):Void
	{
		server = new Socket();
		// server.setBlocking(false);
		final bindPort:Int = port == null ? 0 : port;
		server.bind(new Host(DEFAULT_IP), bindPort);
		server.listen(5);
		serverPort = server.host().port;

		running.store(true);
		Thread.create(() ->
		{
			while (running.load())
			{
				try
				{
					var client = server.accept();
					update(client, root);
					Sys.sleep(0.01);
				}
				catch (e:Exception)
				{
					trace('Failed to update the server: ${e.stack}');
				}
			}
		});

		trace('Running at http://$DEFAULT_IP:$serverPort');
	}

	public static function resolveAsset(path:String):String
	{
		return 'http://$DEFAULT_IP:$serverPort/$path';
	}

	public static function update(client:Socket, root:String):Void
	{
		try
		{
			var requestLine:String = client.input.readLine();

			while (true)
			{
				var line:String = client.input.readLine();
				if (line == null || line.length <= 0)
					break;
			}

			var path:String = requestLine.split(" ")[1];
			if (!path.startsWith('/'))
				path = '/' + path;

			var queryIndex = path.indexOf('?');
			if (queryIndex != -1)
				path = path.substr(0, queryIndex);
			var absolutePath:String = root + path;

			if (!exists(absolutePath))
			{
				sendError(client);
				return;
			}

			var data:Null<Bytes> = getData(absolutePath);
			var contentType:String = getMime(absolutePath);

			if (data == null)
			{
				sendError(client);
				return;
			}

			var header = formatData(data, contentType);

			client.output.writeString(header);
			client.output.write(data);

			client.output.flush();
		}
		catch (e:Exception)
		{
			trace('Update Error: ${e.stack}');
		}

		client.close();
	}

	public static function closeServer():Void
	{
		if (running.load())
		{
			running.store(false);
			if (server != null)
			{
				server.close();
				server = null;
				serverPort = DEFAULT_PORT;
			}
		}
	}

	private static inline function exists(file:String):Bool
	{
		return Resource.listNames().contains(file);
	}

	private static inline function getData(file:String):Null<Bytes>
	{
		trace('Serving file from resources: ${file}');
		return Resource.getBytes(file);
	}

	private static inline function formatData(data:Bytes, mime:String):String
	{
		return "HTTP/1.1 200 OK\r\n"
			+ "Content-Type: "
			+ mime
			+ "\r\n"
			+ "Content-Length: "
			+ data.length
			+ "\r\n"
			+ "Connection: close\r\n\r\n";
	}

	private static function sendError(client:Socket):Void
	{
		var response = "HTTP/1.1 404 Not Found\r\n\r\n404";
		client.output.writeString(response);
	}

	private static function getMime(path:String):String
	{
		return switch (Path.extension(path))
		{
			case "html": Mime.TextHtml;
			case "js": Mime.ApplicationJavascript;
			case "css": Mime.TextCss;
			case "json": Mime.ApplicationJson;
			case "ttf": "font/ttf";
			case "woff": "font/woff";
			case "woff2": "font/woff2";
			default: Mime.ApplicationOctetStream;
		}
	}
}
