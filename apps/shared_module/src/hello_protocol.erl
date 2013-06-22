-module(hello_protocol).

-behaviour(gen_server).

%% API
-export([start_link/0,process/2,check_sign/4]).

%% gen_server callbacks
-export([init/1,
         handle_call/3,
         handle_cast/2,
         handle_info/2,
         terminate/2,
         code_change/3]).

-record(state, {}).
-include("../../shared_module/src/ecomet_router_types.hrl").

%%%===================================================================
%%% API
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc
%% Starts the server
%%
%% @spec start_link() -> {ok, Pid} | ignore | {error, Error}
%% @end
%%--------------------------------------------------------------------
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).


process(Type,Data)->
        gen_server:call(?MODULE,{Type,Data}).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Initializes the server
%%
%% @spec init(Args) -> {ok, State} |
%%                     {ok, State, Timeout} |
%%                     ignore |
%%                     {stop, Reason}
%% @end
%%--------------------------------------------------------------------
init([]) ->
    {ok, #state{}}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling call messages
%%
%% @spec handle_call(Request, From, State) ->
%%                                   {reply, Reply, State} |
%%                                   {reply, Reply, State, Timeout} |
%%                                   {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, Reply, State} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------

check_sign(AppId,Uid,Timestamp,Sign)->
    Secret = "123456",
    Plain = AppId++Uid++Timestamp++Secret,
    
    Md5Str = crypto_util:md5(Plain),  
    error_logger:info_msg("md5sum ~p ~p ~n",[Plain,Md5Str]),
    Sign1 = list_to_binary(Sign),
    if Md5Str == Sign1  ->
        ok;
       true->
        error
    end.
   
handle_call({message,Qs}, _From, State) ->
    Content = proplists:get_value("content",Qs,""),
    AppId = proplists:get_value("appid",Qs,""),
    From = proplists:get_value("from",Qs,""),
    To = proplists:get_value("to",Qs,""),
    Nick = proplists:get_value("nick",Qs,""),
    Type = proplists:get_value("type",Qs,"msg"),
   

    Reply = #message{appId = list_to_binary(AppId),
                           from = list_to_binary(From),
                           to = list_to_binary(To),
                           nick = list_to_binary(Nick),
                           type = list_to_binary(Type),
                           content = list_to_binary(Content)
                           },
   error_logger:info_msg("~p",[Reply]),
   { reply, {ok,Reply}, State};
    

handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling cast messages
%%
%% @spec handle_cast(Msg, State) -> {noreply, State} |
%%                                  {noreply, State, Timeout} |
%%                                  {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_cast(_Msg, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling all non call/cast messages
%%
%% @spec handle_info(Info, State) -> {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_info(_Info, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any
%% necessary cleaning up. When it returns, the gen_server terminates
%% with Reason. The return value is ignored.
%%
%% @spec terminate(Reason, State) -> void()
%% @end
%%--------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Convert process state when code is changed
%%
%% @spec code_change(OldVsn, State, Extra) -> {ok, NewState}
%% @end
%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
