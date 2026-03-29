package;

import haxe.io.Path;
import utils.Util;
import sys.thread.Thread;

import funkinpacker.Loader as FunkinPackerLoader;
import funkinpacker.Server as FunkinPackerServer;

@:cppInclude("signal.h")
@:cppInclude("funkinpacker/Loader.h")
#if windows
@:cppInclude("windows.h")
#end
@:cppNamespaceCode('
static volatile sig_atomic_t shouldExit = 0;
')
class Main
{
	#if windows
	private static function __init__()
	{
		if (!Util.isWebView2Installed())
			Util.webView2Alert();
	}
	#end

	public static function main()
	{
		Util.initCustomTrace();

		// If you ctrl+c on console while the thing is running
		// Then the thing will die cuz server + language server process didn't close
		// These make sure they always close. Both are supposed to be DIFFERENT solutions the SAME THING
		// But for some reason they only do their job when BOTH are implemented
		// So do NOT ever think of getting rid of one.
		Main.registerSignalHandlers();
		#if windows
		Main.startSafeExitThread();
		#end

		FunkinPackerLoader.load(true);
	}

	private static function startSafeExitThread():Void
	{
		Thread.create(() ->
		{
			try
			{
				while (true)
				{
					Sys.stdin().readByte();
					if (!FunkinPackerLoader.running.load())
						break;
				}
			}
			catch (e)
			{
				if (FunkinPackerLoader.running.load())
				{
					FunkinPackerLoader.webview.dispatch((_, _) ->
					{
						FunkinPackerLoader.cleanup();
						Sys.exit(0);
					}, null);
				}
			}
		});
	}

	private static function registerSignalHandlers():Void
	{
		untyped __cpp__('
            struct SH {
                static void handle(int) {
                    shouldExit = 1;
                }
                #ifdef _WIN32
                static BOOL WINAPI console(DWORD) {
                    shouldExit = 1;
                    return TRUE;
                }
                #endif
            };
            ::signal(SIGINT, SH::handle);
            ::signal(SIGTERM, SH::handle);
            #ifdef _WIN32
            ::signal(SIGBREAK, SH::handle);
            ::SetConsoleCtrlHandler(SH::console, TRUE);
            #endif
        ');

		Thread.create(() ->
		{
			while (true)
			{
				if (untyped __cpp__('shouldExit'))
				{
					if (FunkinPackerLoader.running.load() && FunkinPackerLoader.webview != null)
					{
						FunkinPackerLoader.webview.dispatch((_, _) ->
						{
							FunkinPackerLoader.cleanup(false);
							Sys.exit(0);
						}, null);
					}
					break;
				}

				Sys.sleep(0.05);
			}
		});
	}
}
