Setup.Package
{
 	vendor = "liflg.org",
 	id = "smac",
 	description = "Alpha Centauri",
 	version = "6.0a-english",
 	splash = "splash.png",
 	superuser = false,
	write_manifest = true,
 	support_uninstall = true,
 	recommended_destinations =
 	{
 		"/usr/local/games",
		"/opt",
		MojoSetup.info.homedir,
 	},

 	Setup.Readme
 	{
 		description = "README",
 		source = "README.liflg"
 	},

	Setup.Media
 	{
 		id = "smac-disc",
		description = "Alpha Centauri Loki Disc",
		uniquefile = "bin/x86/smac"	
 	},

	Setup.Option {
		required = true,
		description = "Files for Alpha Centauri",
		bytes = 641533132,
                Setup.DesktopMenuItem
                {
                	disabled = false,
			name = "Alpha Centauri",
                        genericname = "Strategy Game",
                        tooltip = "Play Alpha Centauri",
                        builtin_icon = false,
                        icon = "icon.xpm",
                        commandline = "%0/smac.sh",
                        category = "Game",
                },

                Setup.DesktopMenuItem
                {
                	disabled = false,
			name = "Alien Crossfire",
                        genericname = "Strategy Game",
                        tooltip = "Play Alien Crossfire",
                        builtin_icon = false,
                        icon = "icon.xpm",
                        commandline = "%0/smacx.sh",
                        category = "Game",
                },


		Setup.File {
			source = "media://smac-disc/data.tar.gz",
		},

		Setup.File {
			source = "media://smac-disc/bin/x86",
			permissions = "0755",
		},

		Setup.File 
		{
			wildcards = { "smac.sh", "smacx.sh", "smacpack.sh" },
			permissions = "0755",
		},

		Setup.File
		{	
			wildcards = "README.liflg"
		},

		Setup.File {
			source = "media://smac-disc/",
			wildcards = { "data/*", "Alien_Crossfire_Manual.pdf", "Alpha_Centauri_Manual.pdf", "icon.*", "README", "QuickStart.txt" },
		},

		Setup.Option {
			required = true,
			value = true,
			description = "Apply Patch 6.0a",
			tooltip = "Latest update from Loki",
			bytes = 19456000,
			Setup.File
			{
				allowoverwrite = true,
				source = "base:///patch-6.0a.tar.xz/",
				filter = function(dest)
					if ( string.match( dest, "smac" ) ) then
						return dest, "0755"
					end
					return dest
				end
			},
		},

		Setup.Option
		{
			value = true,
			required = true,
			description = "Install Loki-Compat libs",
			bytes = 6439169,
			Setup.File
			{
				source = "base:///loki_compat_libs-1.4.tar.xz/",
			},
		},
	},
}			
