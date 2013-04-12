http = require 'http'
fs = require 'fs'
connect = require 'connect'

clientSideJS = ->

	upload = ({files,url,onProgress,onComplete})->
		xhr = new XMLHttpRequest
		if xhr.upload
			xhr.open "POST", url, true

			formData = new FormData
			if (Array.isArray files) or (files instanceof FileList)
				for file,idx in files
					formData.append "file-#{idx}",file
			else
				formData.append "file",files
			
			if onProgress
				xhr.upload.addEventListener "progress", (e)->
					onProgress e.loaded, e.total
			
			if onComplete
				xhr.onload = ->
					response = JSON.parse if @responseText is '' then '{}' else @responseText
					onComplete @status, response
					
			xhr.send formData

	el = document.getElementById 'drop'

	el.addEventListener 'dragover', (e)->
		e.stopPropagation()
		e.preventDefault()
		
	el.addEventListener 'dragleave', (e)->
		e.stopPropagation()
		e.preventDefault()

	el.addEventListener 'drop', (e)->
		e.stopPropagation()
		e.preventDefault()
		files = e.target.files ? e.dataTransfer.files
		upload
			files: files
			url: '/'
			onProgress: (loaded,total)-> el.textContent = (loaded/total).toFixed 2
			onComplete: -> el.textContent = 'Done'

html = """
<!DOCTYPE HTML>
<html lang="en">
<head>
	<meta charset="UTF-8">
	<title>Drop me the file</title>
	<style type="text/css">
		#drop{
			width:200px;
			height:200px;
			border:3px dotted #333;
			border-radius: 100px;
			text-align: center;
			line-height: 200px;
		}
	</style>
</head>
<body>
	<div id="drop">
		Drop me the file
	</div>
	<script type="text/javascript">
		(#{clientSideJS})()
	</script>
</body>
</html>
"""

handler = (req,res)->
	if req.method is 'GET'
		res.writeHead 200, 'Content-Type': 'text/html'
		res.write html
		res.end()
	else
		numUploadedFiles = numFiles = 0
		for own _,file of req.files
			numFiles += 1
			ws = fs.createWriteStream file.name
			ws.on 'close', (file)->
				numUploadedFiles += 1
				if numUploadedFiles >= numFiles
					res.end()
			rs = fs.createReadStream file.path
			rs.pipe ws

app = connect()

app.use connect.logger ':method :req[content-type]'
app.use connect.bodyParser()
app.use handler

port = process.env.PORT ? 9999

app.listen port

console.log "listen on port #{port}, use PORT=<port> to change default port"
