package utils;

import haxe.macro.Expr.ExprOf;

using StringTools;

@:nullSafety
#if windows
@:cppInclude("windows.h")
@:cppInclude("shellapi.h")
@:cppNamespaceCode("
    static HHOOK g_webview2_hook = NULL;

    static LRESULT CALLBACK WebView2CBTProc(int nCode, WPARAM wParam, LPARAM lParam) {
        if (nCode == HCBT_ACTIVATE) {
            HWND hwnd = (HWND)wParam;

            HWND btnYes = GetDlgItem(hwnd, IDYES);
            if (btnYes) SetWindowTextW(btnYes, L\"Install\");

            HWND btnNo = GetDlgItem(hwnd, IDNO);
            if (btnNo) SetWindowTextW(btnNo, L\"Close\");

            if (g_webview2_hook) {
                UnhookWindowsHookEx(g_webview2_hook);
                g_webview2_hook = NULL;
            }
        }
        return CallNextHookEx(g_webview2_hook, nCode, wParam, lParam);
    }
")
#end
class Util
{
	public static function initCustomTrace():Void
	{
		#if (desktop && sys && !no_console)
		haxe.Log.trace = function(v:Dynamic, ?infos:haxe.PosInfos):Void
		{
			if (infos == null)
				return;
			var str = haxe.Log.formatOutput(v, infos);
			Sys.stdout().writeString(str + '\n');
			Sys.stdout().flush();
		};
		#end
	}

	public static function applyBackslashes(path:String, force:Bool = false):String
	{
		if (#if windows true #else force #end)
			path = path.replace('/', '\\');

		return path;
	}

	public static macro function getDefine(name:String):ExprOf<Null<String>>
	{
		return macro $v{haxe.macro.Context.definedValue(name)};
	}

	#if windows
	@:functionCode("
        const wchar_t* WEBVIEW2_KEY_MACHINE =
            L\"SOFTWARE\\\\WOW6432Node\\\\Microsoft\\\\EdgeUpdate\\\\Clients\\\\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}\";
        const wchar_t* WEBVIEW2_KEY_USER =
            L\"SOFTWARE\\\\Microsoft\\\\EdgeUpdate\\\\Clients\\\\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}\";

        HKEY hKey = NULL;
        bool found = false;

        if (!found && RegOpenKeyExW(HKEY_LOCAL_MACHINE, WEBVIEW2_KEY_MACHINE,
                0, KEY_READ | KEY_WOW64_32KEY, &hKey) == ERROR_SUCCESS) {
            found = true;
            RegCloseKey(hKey);
        }

        if (!found && RegOpenKeyExW(HKEY_LOCAL_MACHINE, WEBVIEW2_KEY_MACHINE,
                0, KEY_READ, &hKey) == ERROR_SUCCESS) {
            found = true;
            RegCloseKey(hKey);
        }

        if (!found && RegOpenKeyExW(HKEY_CURRENT_USER, WEBVIEW2_KEY_USER,
                0, KEY_READ, &hKey) == ERROR_SUCCESS) {
            found = true;
            RegCloseKey(hKey);
        }

        return found;
    ")
	#end
	public static function isWebView2Installed():Bool
	{
		return false;
	}

	#if windows
	@:functionCode("
        g_webview2_hook = SetWindowsHookExW(WH_CBT, WebView2CBTProc, NULL, GetCurrentThreadId());

        int result = MessageBoxW(
            NULL,
            L\"This application requires the Microsoft Edge WebView2 Runtime, which is not installed on your system.\\n\\nClick Install to download it, or Close to exit.\",
            L\"WebView2 Runtime Required\",
            MB_YESNO | MB_ICONWARNING | MB_TOPMOST
        );

        if (result == IDYES) {
            ShellExecuteW(NULL, L\"open\", L\"https://go.microsoft.com/fwlink/p/?LinkId=2124703\", NULL, NULL, SW_SHOWNORMAL);
            Sleep(500);
        }

        ExitProcess(0);
    ")
	#end
	public static function webView2Alert():Void
	{
		return;
	}
}
