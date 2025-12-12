-module(og_image_native).
-export([render_image/6]).
-on_load(init/0).

-define(APPNAME, og_image).
-define(LIBNAME, og_image_nif).
-define(VERSION, "1.1.0").
-define(GITHUB_REPO, "bigmoves/og_image").

init() ->
    PrivDir = get_priv_dir(),
    {Os, Arch} = detect_platform(),
    NifName = lists:flatten(io_lib:format("~s-~s-~s.so", [?LIBNAME, Os, Arch])),
    NifPath = filename:join(PrivDir, NifName),

    %% Download if not present
    case filelib:is_file(NifPath) of
        true -> ok;
        false -> download_nif(PrivDir, NifName, Os, Arch)
    end,

    %% Load the NIF (without .so extension)
    NifPathNoExt = filename:join(PrivDir, lists:flatten(io_lib:format("~s-~s-~s", [?LIBNAME, Os, Arch]))),
    erlang:load_nif(NifPathNoExt, 0).

get_priv_dir() ->
    case code:priv_dir(?APPNAME) of
        {error, bad_name} ->
            case file:read_file_info("priv") of
                {ok, _} -> "priv";
                _ ->
                    EbinDir = filename:dirname(code:which(?MODULE)),
                    filename:join(filename:dirname(EbinDir), "priv")
            end;
        Dir -> Dir
    end.

detect_platform() ->
    Os = case os:type() of
        {unix, darwin} -> "macos";
        {unix, linux} -> "linux";
        {unix, _} -> "linux";  % Assume linux-compatible for other unix
        _ -> "unknown"
    end,

    Arch = case erlang:system_info(system_architecture) of
        "aarch64" ++ _ -> "arm64";
        "arm64" ++ _ -> "arm64";
        "x86_64" ++ _ -> "x86_64";
        "amd64" ++ _ -> "x86_64";
        _ -> "x86_64"  % Default fallback
    end,

    {Os, Arch}.

download_nif(PrivDir, NifName, Os, Arch) ->
    Url = lists:flatten(io_lib:format(
        "https://github.com/~s/releases/download/v~s/~s",
        [?GITHUB_REPO, ?VERSION, NifName]
    )),
    io:format("og_image: Downloading NIF for ~s-~s...~n", [Os, Arch]),

    %% Ensure priv dir exists
    ok = filelib:ensure_dir(filename:join(PrivDir, "dummy")),

    %% Start required applications
    {ok, _} = application:ensure_all_started(ssl),
    {ok, _} = application:ensure_all_started(inets),

    NifPath = filename:join(PrivDir, NifName),

    %% GitHub releases redirect to S3, so we need to follow redirects
    HttpOpts = [
        {ssl, [{verify, verify_none}]},
        {autoredirect, true}
    ],
    Opts = [{body_format, binary}],

    case httpc:request(get, {Url, []}, HttpOpts, Opts) of
        {ok, {{_, 200, _}, _, Body}} ->
            ok = file:write_file(NifPath, Body),
            io:format("og_image: Downloaded ~s (~.1f MB)~n", [NifName, byte_size(Body) / 1048576]);
        {ok, {{_, Code, Reason}, _, _}} ->
            error({nif_download_failed, Code, Reason, Url});
        {error, Reason} ->
            error({nif_download_failed, Reason, Url})
    end.

%% NIF stub - replaced when NIF loads
render_image(_JsonStr, _Width, _Height, _Format, _Quality, _Resources) ->
    erlang:nif_error(nif_not_loaded).
