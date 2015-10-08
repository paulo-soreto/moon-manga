--
-- Programa para tdownload de mangás.
-- @author  Paulo Soreto
-- @date    06/10/2015
-- @version 0.0.5
-- @contact psoreto@gmail.com
--

http = require 'socket.http'
base = 'http://mangafox-br.org/leitor/'
title = arg[1]\gsub '%s+', '_'
chapter = 0
source = ''

--
-- log
--
-- Registra uma mensagem no arquivo de logs.
--
-- @param   message string  Mensagem
--
log = (message) ->
    file = io.open 'log', 'a'
    file\write message.."\n"
    file\close!

--
-- list
--
-- Lista todos os mangás disponíveis em uma table.
--
-- @return  table   Mangás
--
list = ->
    r, c, h = http.request 'http://mangafox-br.org/lista-de-mangas'
    if c == 404
        print '[Erro]', 'Fonte inválida.'
        print '[Aviso]', 'Entre em contato com o desenvolvedor para solucionar o problema.'
        os.exit!
    elseif c != 200 then return false

    mangas = {}
    for manga in r\gmatch '/mangas/[^/]*">([^>]*)</a>' do table.insert mangas, manga
    return mangas

--
-- saerch
--
-- Pesquisa por um mangá (case-sensitive).
--
-- @param   name    string  Nome do mangá.
--
search = (name) ->
    result = [m for i, m in ipairs list! when m\find name]
    for i = 1, #result do print result[i]

--
-- dirExists
--
-- Verifica se o diretório existe. Lua não possui por padrão um método para isso
--
-- @param   dir     string  Diretório
-- @return  bool
--
dirExists = (dir) ->
    r, e, c = os.rename dir, dir
    return r or false

--
-- saveImage
--
-- Armazena a imagem.
--
-- @param   name    string  Nome do arquivo
-- @param   image   string  Arquivo
--
saveImage = (name, image) ->
    dir = { manga: './'..title, chapter: './'..title..'/'..chapter }

    if not dirExists dir.manga then os.execute 'mkdir '..dir.manga
    if not dirExists dir.chapter then os.execute 'mkdir '..dir.chapter

    file = io.open dir.chapter..'/'..name, 'w'
    file\write image
    file\close!

--
-- downloadImage
--
-- Baixa a imagem e salva na pasta da capítulo dentro da pasta do mangá correspondente.
--
-- @param   site    string  Domínio onde está hospedada a imagem.
-- @param   num     int     Número do capítulo.
-- @param   image   string  Nome do arquivo com extenção.
-- @return  bool    Resultado da transferência.
--
downloadImage = (site, num, image) ->
    req, c, h = http.request 'http://'..site..'/leitor/mangas/'..title\gsub('_', ' ')..'/'..num..'/'..image
    if c == 404
        print '[Erro] Não foi possível baixar imagem.'
        log '[404] http://'..site..'/leitor/mangas/'..title\gsub('_', ' ')..'/'..num..'/'..image
        os.exit!
    elseif c > 500
        print '[Aviso] Falha ao baixar imagem, tentanto novamente.'
        for i = 0, 4 do
            req, c, h = http.request 'http://'..site..'/leitor/mangas/'..title\gsub('_', ' ')..'/'..num..'/'..image
            if c > 500 then return false
            elseif c == 200 then saveImage image, req
            else return false
    elseif c == 200
        saveImage image, req
        return true

--
-- downloadChapter
--
-- Baixa um determinado capítulo.
--
-- @param   number  int   Número do capítulo.
-- @return  bool    Resultado da transferência.
--
downloadChapter = (number) ->
    r, c, h = http.request base..title..'/'..number
    if c == 404
        print '[Erro]', 'Fonte inválida.', base..title..'/'..number
        print '[Aviso]', 'Entre em contato com o desenvolvedor para solucionar o problema.'
        os.exit!
    elseif c != 200
        print c
        return false, c

    print 'Baixando capítulo: ', number
    site = r\match 'http://([^/]*)/leitor/mangas'
    for i = 1, 1000 do
        r, c, h = http.request source..'/'..i
        image = r\match '/'..number..'/([^/]+%.[jpn]+e?g)'
        if c == 200 and image then downloadImage site, number, image
        else
            if r\find '<title>Mangás Fox -' then print '[Erro]', 'Mangá incorreto ou inexistente!'
            break

    return true

--
-- Main
--
main = ->
    -- list
    if arg[1] == '-l' then for _, v in pairs list! do print v
    -- search
    elseif arg[1] == '-s' then search arg[2]
    -- download
    else
        min, max = arg[2]\match '(%d+)%-(%d+)'
        if not min or not max then min, max = arg[2], arg[2]
        for i = tonumber(min), tonumber(max) do
            n = if i < 10 then '0'..i else i
            chapter, source, result = i, base..title..'/'..n, false
            while result == false do result, code = downloadChapter n

main!
