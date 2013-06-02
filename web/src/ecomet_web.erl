%% @author Mochi Media <dev@mochimedia.com>
%% @copyright 2010 Mochi Media <dev@mochimedia.com>

%% @doc Web server for ecomet.

-module(ecomet_web).
-author("zhangjiayin <zhangjiayin99@gmail.com>").

-export([start/1, stop/0, loop/2, feed/3, loop/1]).

-export([ resume/2 ]).
-define(LOOP, {?MODULE, loop}).
-define(WAITTIME, 30000).
%% External API

start(Options) ->
    {DocRoot, Options1} = get_option(docroot, Options),
    {ClusterNodes, Options2} = get_option(cluster_nodes, Options1),
    lists:foreach(fun(X)->net_adm:ping(X) end, ClusterNodes),
    Loop = fun (Req) ->
                   ?MODULE:loop(Req, DocRoot)
           end,
        mochiweb_http:start([{max,1000000},{name, ?MODULE}, {loop, Loop} | Options2]).

stop() ->
    mochiweb_http:stop(?MODULE).

loop(Req, DocRoot) ->
    "/" ++ Path = Req:get(path),
    try
        case Req:get(method) of
            Method when Method =:= 'GET'; Method =:= 'HEAD' ->
                case Path of
                    "ecomet/" ++ Id ->
                        Response = Req:ok({"text/html; charset=utf-8",
                                [{"Server","Mochiweb-Test"}],
                                chunked}),
                        gen_server:call({global, ecomet_router}, {login,Id,self(),true}),
                        proc_lib:hibernate(?MODULE, feed, [Response, Id, 1]);
                    "longpoll/" ++ Id      ->
                        gen_server:call({global, ecomet_router}, {login,Id,self(),true}),
                        error_logger:error_report(["loop/2"]),
                        Reentry = mochiweb_http:reentry(?LOOP),
                        proc_lib:hibernate(?MODULE, resume, [Req, Reentry]),
                        io:format("not gonna happen~n", []);
                    _ ->
                        Req:serve_file(Path, DocRoot)
                end;
            'POST' ->
                case Path of
                    _ ->
                        Req:not_found()
                end;
            _ ->
                Req:respond({501, [], []})
        end
    catch
        Type:What ->
            Report = ["web request failed",
                      {path, Path},
                      {type, Type}, {what, What},
                      {trace, erlang:get_stacktrace()}],
            error_logger:error_report(Report),
            %% NOTE: mustache templates need \ because they are not awesome.
            Req:respond({500, [{"Content-Type", "text/plain"}],
                         "request failed, sorry\n"})
    end.

%% Internal API
feed(Response,Id,N) ->
    receive
    {router_msg, Msg} ->
        Html = io_lib:format("Recvd msg #~w: '~s'", [N, Msg]),
        Response:write_chunk(Html);
    _ ->
        ok
    after 1000 ->
            ok
    end,
    proc_lib:hibernate(?MODULE, feed, [Response, Id, 1]).

get_option(Option, Options) ->
    {proplists:get_value(Option, Options), proplists:delete(Option, Options)}.

%%
%% Tests
%%
-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").

you_should_write_a_test() ->
    ?assertEqual(
       "No, but I will!",
       "Have you written any tests?"),
    ok.

-endif.

loop(Req) ->
    "/" ++ Path = Req:get(path),
    try
        case Req:get(method) of
            Method when Method =:= 'GET'; Method =:= 'HEAD' ->
                case Path of
                    %%"ecomet/" ++ Id ->
                    %%  Req:not_found();
                    "longpoll/" ++ Id      ->
                        Reentry = mochiweb_http:reentry(?LOOP),
                        erlang:send_after(?WAITTIME, self(), "ping"),
                        error_logger:error_report(["loop/1"]),
                        error_logger:error_report([Id]),
                        proc_lib:hibernate(?MODULE, resume, [Req, Reentry]);
                    _ ->
                        Req:not_found()
                end;
            'POST' ->
                case Path of
                    _ ->
                        Req:not_found()
                end;
            _ ->
                Req:respond({501, [], []})
        end
    catch
        Type:What ->
            Report = ["web request failed",
                      {path, Path},
                      {type, Type}, {what, What},
                      {trace, erlang:get_stacktrace()}],
            error_logger:error_report(Report),
            %% NOTE: mustache templates need \ because they are not awesome.
            Req:respond({500, [{"Content-Type", "text/plain"}],
                         "request failed, sorry\n"})
    end.


resume(Req, Reentry) ->
    error_logger:error_report(["resume/2"]),
    receive
        Msg ->
            Text = io_lib:format("wake up message: ~p~nrest of path: ~p", [Msg, self()]),
            ok(Req, Text)
    after  ?WAITTIME ->
        ok
    end,

    io:format("reentering loop via continuation in ~p~n", [Req:get(path)]),
    Reentry(Req).

ok(Req, Response) ->
    Req:ok({_ContentType = "text/plain",
            _Headers = [],
            Response}).
