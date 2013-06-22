<?php
    $secret = "123456";
    $user_id = 1;
    $app_id = 1;
    $timestamp = time();
    $plain = "$app_id$user_id$timestamp$secret";
    echo "$plain<br/>";
    $sign = md5($plain);
    echo $sign;  
?>
<html>
<head>
        <script src="js/jquery-2.0.2.min.js"></script>
</head>

<body>
    test longpoll
    <div id="content">
    </div>

    <script>
        retry_time = 1;
        function longPoll() {
            $.ajax({
                type: "GET",
                url: "http://ecomet.etao.com:8080/longpoll/1?",
                data: {uid:"<?php echo $user_id;?>",
                       timestamp:"<?php echo $timestamp;?>",
                       sign:"<?php echo $sign;?>"
                      },
                cache:false,
                dataType: "json",
                success: function(ret){ 
                    if(ret.result==0){
                        retry_time = 1;
                        $("#content").append(ret.content);
                        longPoll();
                    } else {
                        $("#content").append(ret.msg+"<br/>");
                        retry_time = retry_time * 2;
                        setTimeout(longPoll, retry_time*1000);
                    }
                    
                },
                error : function() {
                    retry_time = retry_time * 2;
                    setTimeout(longPoll, retry_time*1000);
                }
            });
        }

        $(document).ready(function(){
            longPoll();
        });
    </script>
</body>
</html>
