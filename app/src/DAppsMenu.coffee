_ = require 'underscore'
path = require 'path'

module.exports = (gui) ->
	class DAppsMenu
		constructor: ({@eth, @ipfs, @config}) ->
			@menu = new gui.Menu()
			@dappWindows = []
			@rootItem = new gui.MenuItem
				label: '\u00D0Apps'
				submenu: @menu

			@newDappMenu =  new gui.Menu()

			@newDappMenu.append new gui.MenuItem
				label: 'From IPFS hash'
				click: =>
					ipfsHash = window.prompt("Please enter the IPFS content hash of the \u00D0App to add.")
					name = window.prompt("What name would you like to save that dapp as?")
					return unless ipfsHash and name
					@addIPFSDApp( name, ipfsHash )


			@newDappMenu.append new gui.MenuItem
				label: 'Local File'
				click: =>
					chooser = window.document.querySelector('#addFile')
					chooser.addEventListener "change", (evt) =>
						filePath = evt.target.value
						gui.Window.get().hide()
						name = window.prompt("What name would you like to save that dapp as?")
						@addLocalDApp( name, filePath ) if name and filePath
					chooser.click()

			@menu.append new gui.MenuItem
				label: 'Add \u00D0App'
				submenu: @newDappMenu

			@menu.append new gui.MenuItem
				label: 'Basic Wallet'
				click: => @openDApp('wallet')

			for dapp in @config.get('ipfsDApps')
				do (dapp) =>
					@menu.append @getIPFSDAppMenu( dapp.name, dapp.hash )

			for dapp in @config.get('localDApps')
				do (dapp) =>
					@menu.append @getLocalDAppMenu( dapp.name, dapp.path )

		get: -> @rootItem
		closeAll: -> w.close(true) for w in @dappWindows

		getIPFSDAppMenu: (name, hash) =>
			menu = new gui.Menu()
			menuItem = new gui.MenuItem
				label: name
				submenu: menu
			open = new gui.MenuItem
				label: 'Open'
				click: => @openDAppFromIPFSHash(hash)
			remove = new gui.MenuItem
				label: 'Remove'
				click: =>
					#if (window.confirm "Are you sure you want to delete the DApp: #{ name }")
					@menu.remove( menuItem )
					@removeIFPSDApp(name, hash )
			menu.append( open )
			menu.append( remove )
			menuItem

		getLocalDAppMenu: (name, path) =>
			menu = new gui.Menu()
			menuItem = new gui.MenuItem
				label: name
				submenu: menu
			open = new gui.MenuItem
				label: 'Open'
				click: => @openDAppFromFolder(path)
			remove = new gui.MenuItem
				label: 'Remove'
				click: =>
					#if (window.confirm "Are you sure you want to delete the DApp: #{ name }")
					@menu.remove( menuItem )
					@removeLocalDApp(name, path )
			menu.append( open )
			menu.append( remove )
			menuItem

		addIPFSDApp: (name,hash) ->
			@config.flags.ipfsDApps.push({name,hash})
			@config.saveFlag( 'ipfsDApps' )
			@menu.append @getIPFSDAppMenu( name, hash )
			@openDAppFromIPFSHash(hash)

		removeIFPSDApp: (name, hash) ->
			@config.flags.ipfsDApps = _.without(@config.flags.ipfsDApps, _.findWhere(@config.flags.ipfsDApps, {name, hash}))
			@config.saveFlag( 'ipfsDApps' )

		addLocalDApp: (name,path) ->
			@config.flags.localDApps.push({name,path})
			@config.saveFlag( 'localDApps' )
			@menu.append @getLocalDAppMenu( name, path )
			@openDAppFromFolder(path)

		removeLocalDApp: (name, path) ->
			@config.flags.localDApps = _.without(@config.flags.localDApps, _.findWhere(@config.flags.localDApps, {name, path}))
			@config.saveFlag( 'localDApps' )

		getWindowOptions: ->
			"inject-js-start": "app/js/web3.js"
			"inject-js-end": "app/js/web3-provider-setup.js"
			"new-instance": true
			icon: "app/images/icon-tray.ico"
			title: "Ethos"
			toolbar: @config.getBool( 'debug' )
			frame: true
			show: true
			show_in_taskbar: true
			width: 800
			height: 500
			position: "center"
			min_width: 400
			min_height: 200

		openDAppFromIPFSHash: (hash) ->
			url = "http://#{ @ipfs.getGateway() }/ipfs/#{ hash }"
			console.log "Opening DApp at #{url}", 
			@dappWindows.push( gui.Window.open( url, @getWindowOptions() ))

		openDAppFromFolder: (path) ->
			console.log "Opening DApp at #{ path }"
			@dappWindows.push( gui.Window.open( path, @getWindowOptions() ) )

		openDApp: (name) ->
			console.log "Opening #{name} DApp"
			@dappWindows.push( gui.Window.open( "app://ethos/ipfs/#{name}/index.html", @getWindowOptions() ) )

