-module(og_image_native).
-export([hello/0, render_image/5]).
-on_load(init/0).

-define(APPNAME, og_image).
-define(LIBNAME, og_image_nif).

init() ->
    PrivDir = case code:priv_dir(?APPNAME) of
        {error, bad_name} ->
            %% Fallback for development: look relative to current dir
            case file:read_file_info("priv") of
                {ok, _} -> "priv";
                _ ->
                    %% Try relative to the beam file
                    EbinDir = filename:dirname(code:which(?MODULE)),
                    filename:join(filename:dirname(EbinDir), "priv")
            end;
        Dir -> Dir
    end,

    %% Detect platform
    {Os, Arch} = detect_platform(),

    %% Try platform-specific binary first, then generic
    PlatformLib = filename:join(PrivDir, io_lib:format("~s-~s-~s", [?LIBNAME, Os, Arch])),
    GenericLib = filename:join(PrivDir, atom_to_list(?LIBNAME)),

    case erlang:load_nif(PlatformLib, 0) of
        ok -> ok;
        {error, _} ->
            %% Fall back to generic binary name
            erlang:load_nif(GenericLib, 0)
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

%% NIF stubs - replaced when NIF loads
hello() ->
    erlang:nif_error(nif_not_loaded).

render_image(_JsonStr, _Width, _Height, _Format, _Quality) ->
    erlang:nif_error(nif_not_loaded).
