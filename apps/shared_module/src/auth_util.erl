-module(auth_util).

-behaviour(gen_server).

%% API
-export([start_link/0,generate_key/0,get_key/1]).

%% gen_server callbacks
-export([init/1,
         handle_call/3,
         handle_cast/2,
         handle_info/2,
         terminate/2,
         code_change/3]).

-define(AUTH_KEY, auth_key).
-define(ALLOW_STR,"0123456789abcdefghijklmnopqrstuvwxyz").

-record(state, {}).
-record(auth_key,{appid::integer(),key::string()|binary()}).


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
    mnesia:start(),
    case mnesia:create_table(?AUTH_KEY, [{disc_copies,[node()]},{type,ordered_set}]) of
         {atomic, ok} ->
             ok;
         Msg  ->
             error_logger:info_msg("table exists ok ~p",[Msg])
    end,
   
     
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).



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


random_str(Len,AllowedChars)->
    lists:foldl(fun(_, Acc) -> 
                [lists:nth(random:uniform(length(AllowedChars)),  AllowedChars)]  ++ Acc  
                end, [], lists:seq(1, Len)
                ).
  
generate_key()->
    %get the last record
    F = fun() ->
        MaxKey = case mnesia:last(?AUTH_KEY) of
                    '$end_of_table' ->
                                0;
                    Msg->
                                Msg
                  end,

        error_logger:info_msg("MaxKey is ~p ~n",[MaxKey]),
        RandomKey = random_str(8,?ALLOW_STR),
        AuthData  = #auth_key{appid = MaxKey+1 , key = RandomKey},
        mnesia:write(AuthData),
        error_logger:info_msg("~p ~n",[AuthData])
    end,
    mnesia:transaction(F).

get_key(Appid)  ->
     F = fun() ->
        [R|_] = mnesia:read({auth_key,Appid}),
        error_logger:info_msg("~p ~n",[R]),
        R#auth_key.key
    end,
    {atomic,R1} = mnesia:transaction(F),
    R1.
   
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
