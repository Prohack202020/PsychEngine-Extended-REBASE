package mobile;

import lime.system.System as LimeSystem;
import openfl.Lib;
#if android
import android.content.Context as AndroidContext;
import android.os.Environment as AndroidEnvironment;
import android.Permissions as AndroidPermissions;
import android.Settings as AndroidSettings;
#end
#if sys
import sys.FileSystem;
import sys.io.File;
#end
import openfl.events.UncaughtErrorEvent;
import haxe.CallStack;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;

using StringTools;

/**
 * A storage class for mobile.
 * @author Mihai Alexandru (M.A. Jigsaw)
 */
class SUtil
{
	#if sys
	public static function getStorageDirectory(?force:Bool = false):String
	{
		var daPath:String = '';
		#if android
		if (!FileSystem.exists(LimeSystem.applicationStorageDirectory + 'storagetype.txt'))
			File.saveContent(LimeSystem.applicationStorageDirectory + 'storagetype.txt', ClientPrefs.storageType);
		var curStorageType:String = File.getContent(LimeSystem.applicationStorageDirectory + 'storagetype.txt');
		daPath = force ? StorageType.fromStrForce(curStorageType) : StorageType.fromStr(curStorageType);
		daPath = haxe.io.Path.addTrailingSlash(daPath);
		#elseif ios
		daPath = LimeSystem.documentsDirectory;
		#end

		return daPath;
	}

	public static function mkDirs(directory:String):Void
	{
		try {
			if (FileSystem.exists(directory) && FileSystem.isDirectory(directory))
				return;
		} catch (e:haxe.Exception) {
			trace('Something went wrong while looking at folder. (${e.message})');
		}

		var total:String = '';
		if (directory.substr(0, 1) == '/')
			total = '/';

		var parts:Array<String> = directory.split('/');
		if (parts.length > 0 && parts[0].indexOf(':') > -1)
			parts.shift();

		for (part in parts)
		{
			if (part != '.' && part != '')
			{
				if (total != '' && total != '/')
					total += '/';

				total += part;

				try
				{
					if (!FileSystem.exists(total))
						FileSystem.createDirectory(total);
				}
				catch (e:haxe.Exception)
					trace('Error while creating folder. (${e.message})');
			}
		}
	}
	
	public static function saveContent(fileName:String = 'file', fileExtension:String = '.json',
			fileData:String = 'You forgor to add somethin\' in yo code :3'):Void
	{
		try
		{
			if (!FileSystem.exists('saves'))
				FileSystem.createDirectory('saves');

			File.saveContent('saves/' + fileName + fileExtension, fileData);
			showPopUp(fileName + " file has been saved.", "Success!");
		}
		catch (e:haxe.Exception)
			trace('File couldn\'t be saved. (${e.message})');
	}
	
	#if android
	public static function doTheCheck():Void
	{
	    if (!FileSystem.exists(SUtil.getStorageDirectory() + 'assets') && !FileSystem.exists(SUtil.getStorageDirectory() + 'mods'))
		{
			SUtil.showPopUp("Whoops, seems you didn't extract the files from the .APK!\nPlease watch the tutorial by pressing OK.", 'Uncaught Error :(');
			CoolUtil.browserLoad('https://youtu.be/zjvkTmdWvfU');
			LimeSystem.exit(1);
		}
		else
		{
			if (!FileSystem.exists(SUtil.getStorageDirectory() + 'assets'))
			{
				SUtil.showPopUp("Whoops, seems you didn't extract the assets folder from the .APK!\nPlease watch the tutorial by pressing OK.", 'Uncaught Error :(');
				CoolUtil.browserLoad('https://youtu.be/zjvkTmdWvfU');
				LimeSystem.exit(1);
			}

			if (!FileSystem.exists(SUtil.getStorageDirectory() + 'mods'))
			{
				SUtil.showPopUp("Whoops, seems you didn't extract the mods folder from the .APK!\nPlease watch the tutorial by pressing OK.", 'Uncaught Error :(');
				CoolUtil.browserLoad('https://youtu.be/zjvkTmdWvfU');
				LimeSystem.exit(1);
			}
			
			if (!AndroidEnvironment.isExternalStorageManager())
			{
				AndroidSettings.requestSetting('MANAGE_APP_ALL_FILES_ACCESS_PERMISSION');
			}
		}
	}
	#end

	#if android
	public static function doPermissionsShit():Void
	{
		if (!AndroidPermissions.getGrantedPermissions().contains('android.permission.READ_EXTERNAL_STORAGE')
			&& !AndroidPermissions.getGrantedPermissions().contains('android.permission.WRITE_EXTERNAL_STORAGE'))
		{
			AndroidPermissions.requestPermission('READ_EXTERNAL_STORAGE');
			AndroidPermissions.requestPermission('WRITE_EXTERNAL_STORAGE');
			showPopUp('If you accepted the permissions you are all good!' + '\nIf you didn\'t then expect a crash' + '\nPress Ok to see what happens',
				'Notice!');
			if (!AndroidEnvironment.isExternalStorageManager())
			{
				AndroidSettings.requestSetting('MANAGE_APP_ALL_FILES_ACCESS_PERMISSION');
			}
		}
		else
		{
			try
			{
				if (!FileSystem.exists(SUtil.getStorageDirectory()))
					FileSystem.createDirectory(SUtil.getStorageDirectory());
    		}
			catch (e:Dynamic)
			{
				showPopUp('Please create folder to\n' + SUtil.getStorageDirectory(true) + '\nPress OK to close the game', 'Error!');
				LimeSystem.exit(1);
			}
		}
	}

	public static function checkExternalPaths(?splitStorage = false):Array<String> {
		var process = new sys.io.Process('grep -o "/storage/....-...." /proc/mounts | paste -sd \',\'');
		var paths:String = process.stdout.readAll().toString();
		if (splitStorage) paths = paths.replace('/storage/', '');
		return paths.split(',');
	}

	public static function getExternalDirectory(external:String):String {
		var daPath:String = '';
		for (path in checkExternalPaths())
			if (path.contains(external)) daPath = path;

		daPath = haxe.io.Path.addTrailingSlash(daPath.endsWith("\n") ? daPath.substr(0, daPath.length - 1) : daPath);
		return daPath;
	}
	#end
	#end
	public static function showPopUp(message:String, title:String):Void
	{
		#if !ios
		try
		{
			flixel.FlxG.stage.window.alert(message, title);
		}
		catch (e:Dynamic)
			trace('$title - $message');
		#else
		trace('$title - $message');
		#end
	}
}

#if android
enum abstract StorageType(String) from String to String
{
	final forcedPath = '/storage/emulated/0/';
	final packageNameLocal = 'com.kraloyuncu.psychextended';
	final fileLocal = 'PsychEngine';
	final fileLocalNF = 'NF Engine';
	final fileLocalEX = 'Psych Extended'; //idk why

	public static function fromStr(str:String):StorageType
	{
		final EXTERNAL_DATA = AndroidContext.getExternalFilesDir();
		final EXTERNAL_OBB = AndroidContext.getObbDir();
		final EXTERNAL_MEDIA = AndroidEnvironment.getExternalStorageDirectory() + '/Android/media/' + lime.app.Application.current.meta.get('packageName');
		final EXTERNAL = AndroidEnvironment.getExternalStorageDirectory() + '/.' + lime.app.Application.current.meta.get('file');
		final EXTERNAL_NF = forcedPath + '.' + fileLocalNF;
		final EXTERNAL_EX = forcedPath + '.' + fileLocalEX;

		return switch (str)
		{
			case "EXTERNAL_DATA": EXTERNAL_DATA;
			case "EXTERNAL_OBB": EXTERNAL_OBB;
			case "EXTERNAL_MEDIA": EXTERNAL_MEDIA;
			case "EXTERNAL": EXTERNAL;
			case "EXTERNAL_NF": EXTERNAL_NF;
			case "EXTERNAL_EX": EXTERNAL_EX;
			default: SUtil.getExternalDirectory(str) + '.' + fileLocal;
		}
	}

	public static function fromStrForce(str:String):StorageType
	{
		final EXTERNAL_DATA = forcedPath + 'Android/data/' + packageNameLocal + '/files';
		final EXTERNAL_OBB = forcedPath + 'Android/obb/' + packageNameLocal;
		final EXTERNAL_MEDIA = forcedPath + 'Android/media/' + packageNameLocal;
		final EXTERNAL = forcedPath + '.' + fileLocal;
		final EXTERNAL_NF = forcedPath + '.' + fileLocalNF;
		final EXTERNAL_EX = forcedPath + '.' + fileLocalEX;

		return switch (str)
		{
			case "EXTERNAL_DATA": EXTERNAL_DATA;
			case "EXTERNAL_OBB": EXTERNAL_OBB;
			case "EXTERNAL_MEDIA": EXTERNAL_MEDIA;
			case "EXTERNAL": EXTERNAL;
			case "EXTERNAL_NF": EXTERNAL_NF;
			case "EXTERNAL_EX": EXTERNAL_EX;
			default: SUtil.getExternalDirectory(str) + '.' + fileLocal;
		}
	}
}
#end
