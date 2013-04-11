package TBAS;
#use strict;

use Encode;
use Encode::CN;
#use encoding "gbk";
use open IN=>':encoding("gb2312")';
use Spreadsheet::Read;
use Spreadsheet::Wright;
use Spreadsheet::WriteExcel;
use Data::Dumper;
use Smart::Comments;
use Time::Local 'timelocal';

my $valid_year="2011";
my $master_name="cetc28jjb";
my $valid_order="ExportOrderList2011";
use constant SANDAYS    => 30*24*3600;

our %customerreq;
our @servername;
our @customername;
our @customername_list;
our $customercount=0;
our $sessionid;
our $sessionidcount=0;
our @handlecount;
our @customer_req_times;
our $report_file_handle;
our $report_excel_handle;
our @records_date;

our $align_pix=30;

#server info
our @server_name_tmp;
our @server_name_list;
our $server_num;

#sever data
our %trade_server_contribution;
my $ser_baobei_number_index=0;
my $ser_money_index=1;
my $ser_order_num_index=2;
my $ser_chengjiaolv_index=3;
my $ser_customer_number_index=4;
my $ser_goumailv_index=5;

#trade info
our %trade_detail;
our %trade_detail_server;
my $customer_order_number_index=0;
my $order_id_index=1;
my $customer_nicky_name_index=2;
my $customer_mail_index=3;
my $customer_pay_index=4;
my $customer_post_pay_index=5;
my $customer_score_index=6;
my $all_pay_index=7;
my $score_back_index=8;
my $customer_paid_index=9;
my $customer_paid_score_index=10;
my $order_state_index=11;
my $customer_message_index=12;
my $customer_real_name_index=13;
my $customer_address_index=14;
my $transport_index=15;
my $customer_phone_index=16;
my $customer_mobile_index=17;
my $order_created_date_index=18;
my $order_paid_date_index=19;
my $product_title_index=20;
my $product_type_index=21;
my $transport_id_index=22;
my $transport_party_index=23;
my $order_backup_index=24;
my $product_number_index=25;
my $shop_id_index=26;
my $shop_name_index=27;
my $order_close_cause_index=28;
my $sales_fee_index=29;
my $customer_fee_index=30;
my $prodct_per_price_index=31;

my $items_for_one_order=31;
my @freeze_row=(
	"顾客会员名","交易次数","订单编号","买家会员名","买家支付宝账号","买家应付货款",	
	"买家应付邮费",	"买家支付积分",	"总金额","返点积分","买家实际支付金额","买家实际支付积分",	
	"订单状态","买家留言","收货人姓名","收货地址","运送方式","联系电话","联系手机",	
	"订单创建时间","订单付款时间","宝贝标题","宝贝种类","物流单号","物流公司",	
	"订单备注","宝贝总数量","店铺Id","店铺名称","订单关闭原因","卖家服务费","买家服务费","宝贝单价"
  );


#server_trade_info
my @freeze_row2=("客服名字","处理单数","客户","日期","宝贝","数量","总价","单号","单价");
my $tr_num=0;
my $tr_cus_index=1;
my $tr_dat_index=2;
my $tr_baobei_index=3;
my $tr_baobei_amount_index=4;
my $tr_baobei_price_index=5;
my $tr_order_id_index=6;
my $tr_order_per_price=7;

my $server_trade_num=7;

#handled files
my @file_array1;
my @file_array2;
my $filtered_price=30;



sub InitVariables
{
	undef %customerreq;
        undef @servername;
        undef @customername;
        undef @customername_list;
        undef $customercount;
        undef $sessionid;
        undef $sessionidcount;
        undef @handlecount;
        undef @customer_req_times;
        undef $report_file_handle;
        undef @records_date;
        undef @server_name_tmp;
        undef @server_name_list;
        undef $server_num;
        undef @file_array1;
	undef @file_array2;
	undef %trade_detail;
        undef %trade_detail_server;
}
sub InitReportFile{
        my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday)=localtime(time);
	$year+=1900;
	$mon++;
	$report_file_handle=encode("gbk","$main::moduledir/report/Talk$year-$mon-$mday-$hour-$min-$sec.report");
	open(FD,"> $report_file_handle")or die "Can not open $report_file_handle:$!";	
	print FD $report_file_handle;
	close(FD);

}

sub WriteToReport{
        my $input=shift;
        my $output = encode("gb2312",decode_utf8($input));
    	open(FD,">>$report_file_handle") or die "Can not open $report_file_handle:$!";   	
	print FD $output;
	close(FD);    

}

sub __pause_flow($) {
	# Internal helper method
	$main::mw->update();
	$main::mw->after(@_);
}

sub __update_text{
   my $input=shift;
   __pause_flow(100);
   $main::txt -> Insert("\n$input\n ");	
	
}

sub __update_text_decode{
   my $input=shift;
   my $output=decode("gbk",$input);
   __pause_flow(100);
   $main::txt -> Insert("\n$output\n ");	
	
}


sub GetTradeDataByServer
{			
     my $count_index=1;
     
     while((my $key1, my $value1) = each %customerreq)
     {
       my @buf1=split(/\|/,$key1);
       my $customer=$buf1[1];
       my $server=$buf1[2];
       my @date1=split(/\-/,$value1);
       my @time1=split(/:/,$date1[3]);
       my $abs_sec_1=timelocal($time1[2],$time1[1],$time1[0],$date1[2],$date1[1]-1,$date1[0]-1900);
       while((my $key2, my $value2) = each %trade_detail) 
       {
          if($main::state ==0)
          {
     	     return;
          }
          
           my $tempkey=decode("gbk",$key2);           
          
          if($customer eq $tempkey)
          {
          	my $index=0;
          	
          	
          	while($index<$trade_detail{$key2}[$customer_order_number_index])
          	{
          	       my $start_index3=$index * $items_for_one_order;
          	       if($trade_detail{$key2}[$start_index3+$prodct_per_price_index] < $filtered_price)
          	       {
          	       	 $index++;
          	       	 next;
          	       }	       
          	       $trade_detail_server{$server}[$tr_num]=0 unless (defined $trade_detail_server{$server}[$tr_num] );
          	       $trade_detail_server{$server}[$tr_order_id_index]=0 unless (defined $trade_detail_server{$server}[$tr_order_id_index] );                   	                 	       
          	       $trade_detail_server{$server}[$tr_cus_index]=""unless (defined $trade_detail_server{$server}[$tr_cus_index] );
          	       $trade_server_contribution{$server}[$ser_baobei_number_index]=0 unless (defined $trade_server_contribution{$server}[$ser_baobei_number_index] );
          	       $trade_server_contribution{$server}[$ser_money_index]=0 unless (defined $trade_server_contribution{$server}[$ser_money_index] );
          	       $trade_server_contribution{$server}[$ser_order_num_index]=0 unless (defined $trade_server_contribution{$server}[$ser_order_num_index] );
          	       $trade_server_contribution{$server}[$ser_customer_number_index]=0 unless (defined $trade_server_contribution{$server}[$ser_customer_number_index] );
          	       my $start_index2=$trade_detail_server{$server}[$tr_num] * $server_trade_num;
          	       
          	       my $index2=0;
          	       my $continue_flag=1;
          	       while($index2<$trade_detail_server{$server}[$tr_num])
          	       {
          	       	 if($trade_detail_server{$server}[$server_trade_num * $index2+$tr_order_id_index] == $trade_detail{$key2}[$start_index3+$order_id_index])
          	       	 {
          	       	    $continue_flag=0;
          	       	    last;	
          	       	 }
          	       	 $index2++;
          	       }
          	       if ($continue_flag==0)
          	       {
          	       	  $index++; 
          	       	  next;
          	       }
          	             		       
		       my @date2=split(/\-/,$trade_detail{$key2}[$start_index3+$order_created_date_index]);
		       my @time2=split(/:/,$date2[3]);
		       my $abs_sec_2=timelocal($time2[2],$time2[1],$time2[0],$date2[2],$date2[1]-1,$date2[0]-1900);
		       if(($abs_sec_2 > $abs_sec_1) &&(($abs_sec_2 - $abs_sec_1) <= SANDAYS))
		       {
		       	  $trade_detail_server{$server}[$tr_num]++;
		       	  my $index3=0;
		          my $new_customer_flag=1;
          	          while($index3<$trade_detail_server{$server}[$tr_num])
          	          {
          	       	     $trade_detail_server{$server}[$server_trade_num * $index3+$tr_cus_index]="" unless(defined $trade_detail_server{$server}[$server_trade_num * $index3+$tr_cus_index]);
          	       	     if($trade_detail_server{$server}[$server_trade_num * $index3+$tr_cus_index] eq $customer)
          	       	     {
          	       	        $new_customer_flag=0;
          	       	        last;	
          	       	     }
          	       	     $index3++;
          	          }
		          if ($new_customer_flag ==1 )
		          {
		          	$trade_server_contribution{$server}[$ser_customer_number_index]++;
		          }
		          		       	 
		       	  $trade_detail_server{$server}[$start_index2+$tr_cus_index]=$customer;
		       	  $trade_detail_server{$server}[$start_index2+$tr_dat_index]=$trade_detail{$key2}[$start_index3+$order_created_date_index];
		       	  $trade_detail_server{$server}[$start_index2+$tr_baobei_index]=$trade_detail{$key2}[$start_index3+$product_title_index];
		       	  $trade_detail_server{$server}[$start_index2+$tr_baobei_amount_index]=$trade_detail{$key2}[$start_index3+$product_number_index];
		       	  $trade_detail_server{$server}[$start_index2+$tr_baobei_price_index]=$trade_detail{$key2}[$start_index3+$customer_paid_index];
		       	  $trade_detail_server{$server}[$start_index2+$tr_order_id_index]=$trade_detail{$key2}[$start_index3+$order_id_index];
		          $trade_detail_server{$server}[$start_index2+$tr_order_per_price]=$trade_detail{$key2}[$start_index3+$prodct_per_price_index];
		       
		          $trade_server_contribution{$server}[$ser_baobei_number_index]=$trade_server_contribution{$server}[$ser_baobei_number_index] +$trade_detail_server{$server}[$start_index2+$tr_baobei_amount_index];
                          $trade_server_contribution{$server}[$ser_money_index]=$trade_server_contribution{$server}[$ser_money_index] +$trade_detail_server{$server}[$start_index2+$tr_baobei_price_index];		          
		          $trade_server_contribution{$server}[$ser_order_num_index]++;
		          
		          __update_text("有效成交记录 $count_index :$customer,$trade_detail{$key2}[$start_index3+$order_created_date_index],$trade_detail{$key2}[$start_index3+$order_id_index]");
		          $count_index++;          
		          
		       }	                 		          		
          	       $index++;         		
                }          	          	
          }
       }
     }
}




sub GetTradeDataFromFile
{
  my $trade_file_name=encode("gbk",$_[0]);
   
  my $spreadsheet = ReadData($trade_file_name) or die "Cannot read file:$trade_file_name";
  my $sheet_count = $spreadsheet->[0]{sheets} or die "No sheets in $trade_file_name\n";
  my $trade_name_key;
  for my $sheet_index (1 .. $sheet_count)
  {
     if($main::state ==0)
     {
     	      return;
     }
     my $sheet = $spreadsheet->[$sheet_index] or next;
     for my $row (2 .. $sheet->{maxrow}) 
     {
      $trade_name_key=$sheet->{cell}[$customer_nicky_name_index][$row];
      $trade_detail{$trade_name_key}[$customer_order_number_index]=0 unless (defined $trade_detail{$trade_name_key}[$customer_order_number_index] );
      my $order_start_offset=$items_for_one_order * $trade_detail{$trade_name_key}[$customer_order_number_index];
      for my $col (1 .. $sheet->{maxcol})
      {      	   
    	   if($main::state ==0)
           {
     	      return;
           }
      	   if($col == $order_created_date_index )
      	   {
      	      my $date_tmp=$sheet->{cell}[$col][$row];
      	      $date_tmp =~ s/\s+/-/;
      	      $trade_detail{$trade_name_key}[$col+$order_start_offset]= $date_tmp;	
      	   }
      	   else
      	   {
      	     $trade_detail{$trade_name_key}[$col+$order_start_offset]=decode( 'gb2312', $sheet->{cell}[$col][$row] ); #$sheet->{cell}[$col][$row];
     
      	   }
      	   
      }
      $trade_detail{$trade_name_key}[$order_start_offset+$prodct_per_price_index]=0;
      $trade_detail{$trade_name_key}[$order_start_offset+$prodct_per_price_index]=$trade_detail{$trade_name_key}[$order_start_offset+$customer_pay_index]/$trade_detail{$trade_name_key}[$order_start_offset+$product_number_index] if($trade_detail{$trade_name_key}[$order_start_offset+$product_number_index] !=0);

            
      $trade_detail{$trade_name_key}[$customer_order_number_index]++;
      
    };
    
  };
}

sub GenerateTradeReport
{
  my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday)=localtime(time);
  $year+=1900;
  $mon++;
  $report_excel_handle=encode("gbk","$main::moduledir/report/Trade$year-$mon-$mday-$hour-$min-$sec.xls");
  my $workbook = Spreadsheet::WriteExcel->new($report_excel_handle);
  my $worksheet = $workbook->add_worksheet("客户交易数据");
  $worksheet->write_row(0, 0, \@freeze_row);
  $worksheet->freeze_panes(1, 0);
  my $rownumber=1;
  my $customer_index=1;
  my $paid_money=0;
  my $baobei_num=0;
  my $paid_money_actual=0;

  while((my $key, my $value) = each %trade_detail) 
  {
      if($main::state ==0)
      {
     	 return;
      }
	
      #__update_text("$key");
      my @tmparray=@{$trade_detail{$key}};
      if($trade_detail{$key}[$customer_order_number_index] >1)
      {
      	my $index=0;
      	while($index<$trade_detail{$key}[$customer_order_number_index])
      	{
      		
      		if (0==$index)
      		{
      		  my @tmp1=(decode( 'gb2312', $key),$trade_detail{$key}[$customer_order_number_index]);
      		  #$trade_detail{$key}[$prodct_per_price_index]=0;
      		  #$trade_detail{$key}[$prodct_per_price_index]=$tmparray[$customer_pay_index]/$tmparray[$product_number_index] if($tmparray[$product_number_index] !=0);
      		  @tmp1[2..32]=@tmparray[1..31];
      		  #$tmp1[32]=$trade_detail{$key}[$prodct_per_price_index];     		  
      		  $worksheet->write_row($rownumber++, 0, \@tmp1);
      		  $customer_index++;
      		  $paid_money = $paid_money +$trade_detail{$key}[$all_pay_index];      		  
      		  $paid_money_actual = $paid_money_actual +$trade_detail{$key}[$customer_paid_index];
      		  #__update_text("$trade_detail{$key}[$all_pay_index]");
      		  $baobei_num = $baobei_num +$trade_detail{$key}[$product_number_index]; 
      		        		  	
      		}
      		else
      		{
      		  my $start_index=$index * $items_for_one_order +1;
      		  my $last_index=($index+1) * $items_for_one_order;
      		  my @tmp2=("","");
      		  #$trade_detail{$key}[$start_index+$prodct_per_price_index-1]=0;
      		  #$trade_detail{$key}[$start_index+$prodct_per_price_index-1]=$tmparray[$start_index+$customer_pay_index-1]/$tmparray[$start_index+$product_number_index-1] if($tmparray[$start_index+$product_number_index-1] !=0);
      		  @tmp2[2..32]=@tmparray[$start_index..$last_index];
      		  #$tmp2[32]=$trade_detail{$key}[$start_index+$prodct_per_price_index-1];
      		  $worksheet->write_row($rownumber++, 0, \@tmp2);
      		  $paid_money = $paid_money +$trade_detail{$key}[$start_index+$all_pay_index-1];
      		  $paid_money_actual = $paid_money_actual +$trade_detail{$key}[$start_index+$customer_paid_index-1];
      		  #__update_text("$trade_detail{$key}[$start_index+$all_pay_index-1]");
      		  $baobei_num = $baobei_num +$trade_detail{$key}[$start_index+$product_number_index-1]; 	
      		}
      		$index++;
      	}
      	#__update_text("------------");
      	#__update_text($paid_money);
      	#__update_text("------------");
      	
      	$rownumber++
      	
      }
      else
      {
      	 my @tmp3=(decode( 'gb2312', $key ),$trade_detail{$key}[$customer_order_number_index]);
      	 #$trade_detail{$key}[$prodct_per_price_index]=0;
      	 #$trade_detail{$key}[$prodct_per_price_index]=$tmparray[$customer_pay_index]/$tmparray[$product_number_index] if($tmparray[$product_number_index] !=0);
      	 @tmp3[2..32]=@tmparray[1..31];
      	 #$tmp3[32]=$trade_detail{$key}[$prodct_per_price_index];      		  
      	 $worksheet->write_row($rownumber++, 0, \@tmp3);
      	 $rownumber++;
      	 $customer_index++;
      	 $paid_money = $paid_money +$trade_detail{$key}[$all_pay_index];
      	 $paid_money_actual = $paid_money_actual +$trade_detail{$key}[$customer_paid_index];
      	 #__update_text("$trade_detail{$key}[$all_pay_index]");
      	 $baobei_num = $baobei_num +$trade_detail{$key}[$product_number_index];
      }	
  }
  __update_text("-----------------------------------------------------------");
  __update_text("交易情况:");
  $worksheet->write_string($rownumber++, 0, "顾客总人数:$customer_index");
  __update_text("参与交易顾客总人数:$customer_index");
  $worksheet->write_string($rownumber++, 0, "顾客理论支付总金额:$paid_money");
  __update_text("参与交易顾客理论支付总金额:$paid_money");
  $worksheet->write_string($rownumber++, 0, "顾客实际支付总金额:$paid_money_actual");
  __update_text("参与交易顾客实际支付总金额:$paid_money_actual");
  $worksheet->write_string($rownumber++, 0, "顾客实际购买宝贝总数量:$baobei_num");
  __update_text("参与交易顾客实际购买宝贝总数量:$baobei_num");
  __update_text("-----------------------------------------------------------");
  
  
  
  
  my $worksheet2 = $workbook->add_worksheet("客服数据");
  $worksheet2->write_row(0, 0, \@freeze_row2);
  $worksheet2->freeze_panes(1, 0);
  my $rownumber2=1;
  while((my $key2, my $value2) = each %trade_detail_server) 
  {
      if($main::state ==0)
      {
     	 return;
      } 
      my @tmparray2=@{$trade_detail_server{$key2}};
      if($trade_detail_server{$key2}[$tr_num] >1)
      {
      	my $index2=0;
      	while($index2<$trade_detail_server{$key2}[$tr_num])
      	{
      		
      		if (0==$index2)
      		{
      		  my @tmp4=($key2,$trade_detail_server{$key2}[$tr_num]);
      		  @tmp4[2..8]=@tmparray2[1..7];
      		  $worksheet2->write_row($rownumber2++, 0, \@tmp4);     		        		  	
      		}
      		else
      		{
      		  my $start_index2=$index2 * $server_trade_num+1;
      		  my $last_index2=($index2+1) * $server_trade_num;
      		  my @tmp5=("","");
      		  @tmp5[2..8]=@tmparray2[$start_index2..$last_index2];
      		  $worksheet2->write_row($rownumber2++, 0, \@tmp5);	
      		}
      		$index2++;
      	}
      	
      	$rownumber2++
      	
      }
      else
      {
      	 my @tmp6=($key2,$trade_detail_server{$key2}[$tr_num]);
      	 @tmp6[2..8]=@tmparray2[1..7];
      	 $worksheet2->write_row($rownumber2++, 0, \@tmp6);
      	 $rownumber2++;
      }
  }
  
  __update_text("-----------------------------------------------------------");
  __update_text("客服贡献:");
  
  while((my $key3, my $value3) = each %trade_server_contribution) 
  {
	   my $index=0;
	   while ($index<@server_name_list)
	   {
	   	  if($main::state ==0)
	          {
	     	     return;
	          }
	          if($server_name_list[$index] eq $key3)
	          {
	          	$trade_server_contribution{$key3}[$ser_chengjiaolv_index]=100*( $trade_server_contribution{$key3}[$ser_order_num_index]/$handlecount[$index]);
	          	last;
	          }
	  
		   $index++;
		  	
	   }  	 
  	 $trade_server_contribution{$key3}[$ser_goumailv_index]=0;
  	 $trade_server_contribution{$key3}[$ser_goumailv_index]=100*($trade_server_contribution{$key3}[$ser_baobei_number_index]/$trade_server_contribution{$key3}[$ser_customer_number_index]) if($trade_server_contribution{$key3}[$ser_customer_number_index]!=0);
  	 
  	 $worksheet2->write_string($rownumber2++, 0, "客服$key3 ：处理单数：$trade_server_contribution{$key3}[2],卖出宝贝：$trade_server_contribution{$key3}[0]件,服务客户：$trade_server_contribution{$key3}[$ser_customer_number_index]个,直接经济效应：$trade_server_contribution{$key3}[1] 元,成交率：$trade_server_contribution{$key3}[3]\%,平均购买率：$trade_server_contribution{$key3}[$ser_goumailv_index]\%");
 	 __update_text("客服$key3 ：处理单数：$trade_server_contribution{$key3}[2],卖出宝贝：$trade_server_contribution{$key3}[0]件,服务客户：$trade_server_contribution{$key3}[$ser_customer_number_index]个,直接经济效应：$trade_server_contribution{$key3}[1] 元,成交率：$trade_server_contribution{$key3}[3]\%,平均购买率：$trade_server_contribution{$key3}[$ser_goumailv_index]\%");

  }

  __update_text("-----------------------------------------------------------");  
  
  
  $workbook->close();	
}


sub GetUsrDataFromFile
{
  my $record_name=encode("gbk",$_[0]);
  my $cfd;
  #my $newsessionflag=0;
  my $servername;
  my @date=split(/\./,$record_name);
   
  print "GetUsrDataFromFile:$record_name\n";
  if(!open($cfd, "<:encoding(gb2312)",$record_name))
  {
    __update_text("打开文件:$record_name 失败");
    return;	
  }
  while ((<$cfd>))
  {
  	if($main::state ==0)
  	{
  	  close($cfd);
  	  return;	
  	}
  	#$line_buf=encode("gb2312",$_);
        my $line_buf=$_;
        #print "$line_buf\n";
  	chomp $line_buf;
  	my @line_buf_part=split(/\s+/,$line_buf);
  	

  	
  	my $line_buf_part_num=scalar(@line_buf_part);
  	if($line_buf_part_num==1)
  	{
           if($line_buf_part[0] =~ /^$master_name/)
           {
             $servername=$line_buf_part[0];
             push(@server_name_tmp,$servername);	
             #$newsessionflag=1;
           } 	    
   	    next; 	  
  	}
  	
  	#if(defined $line_buf_part[0])
  	if ($line_buf_part_num >1)
  	{ 		
	  	if($line_buf_part[0] !~ /^2011年(0?\d|1[012])月(0?\d|[12]\d|3[01])日\d{2}:\d{2}:\d{2}/)
	  	{next;}
	  	
	  	$line_buf_part[0] =~ s/年/-/;
	  	$line_buf_part[0] =~ s/月/-/;
	  	$line_buf_part[0] =~ s/日/-/;

	    	if($line_buf_part[0]=~ /^$valid_year/)
	  	{
	  	   #__update_text("$line_buf_part[0]");
	  	   #__update_text("$line_buf");
	  	   my @line_buf_part2=split(/:/,$line_buf_part[1]);	
	  	   if($line_buf_part2[0] !~ /^cetc28jjb/)
	  	   {
	  	      #__update_text("客户名字：$line_buf_part2[0]");
	  	      push(@customername,$line_buf_part2[0]);
	  	      #if($newsessionflag==1)
	  	      #{
	  	        $sessionid="$date[0]|$line_buf_part2[0]|$servername";
	  	        if(exists $customerreq{$sessionid})
	  	        {
	  	          #__update_text("$sessionid已经存在");
	  	          if($line_buf_part[0] lt $customerreq{$sessionid})
	  	          {
	  	          	$customerreq{$sessionid}=$line_buf_part[0];
	  	          }	
	  	        }
	  	        else
	  	        {
	                    $customerreq{$sessionid}=$line_buf_part[0];	                   
	                    #__update_text("找到一次会话:$sessionid,$line_buf_part[0]");
	        	
	  	        }
	  	        
	  	      	
	  	      #}
	  	   }	
	  	} 	
  	}
	# $line_buf = <$cfd>; 		

  }
  close($cfd);
  
  my %temphash1=map{$_,1}@server_name_tmp;
  @server_name_list=sort keys %temphash1;
  $server_num=scalar(@server_name_list); 
  __update_text("-----------------------------------------------------------");
  __update_text("客服总共$server_num 人：");
=pod  
  my $index1=0;
  while($index1 < $server_num)
  {
     if($main::state ==0)
     {
     	return;
     }
      $index1++; 
     __update_text("$index1.$server_name_list[$index1 -1]"); 
	
  }  
  __update_text("-----------------------------------------------------------");
=cut  
  my %temphash2=map{$_,1}@customername;
  @customername_list=sort keys %temphash2;
  $customercount=scalar(@customername_list);
  
  __update_text("客户总共$customercount 人：");
  my $index2=0;
  while($index2 < $customercount)
  {
     if($main::state ==0)
     {
     	return;
     }
      $index2++; 
     #__update_text("$index2.$customername_list[$index2 -1]"); 
	
  }    
  __update_text("-----------------------------------------------------------");
}
	


sub GetRecordsFiles
{
   print "GetRecordsFiles\n";
   
   InitVariables();
   InitReportFile();
   my $handle_dir=encode("gbk","$main::dir");
   print "$handle_dir\n";
   opendir(FIL,$handle_dir) or die "Fail to open \"$handle_dir\"!\n";
   my @record_file_list=readdir(FIL);
   foreach my $record_file_name(@record_file_list)
   {
   	if($main::state ==0)
        {
     	      return;
        }
 	
   	if(($record_file_name =~ /^$valid_year/) || ($record_file_name =~ /^$valid_order/))
   	{
   	  push(@file_array1,$record_file_name);	
   	}
   	
   }
   if (@file_array1)
   {
   	@file_array2=@file_array1;
   	my $filename=pop(@file_array1);
   	__update_text("可处理的文件为：");
   	while(defined $filename)
   	{
   	  __update_text("$filename");
   	  $filename=pop(@file_array1);   	  	
   	}  	  	
   }
   else
   {
       __update_text("未找到有效的文件记录!");
       return;	
   }
   
   __update_text("提取信息...");   

   my $filename2=pop(@file_array2);
   my $file_index=0;
   while(defined $filename2)
   {
   	  if($main::state ==0)
          {
     	      return;
          }
	  if($filename2 =~ /^$valid_year/)
	  {
	  	__update_text("-----------------------------------------------------------");
	  	__update_text("处理文件：$filename2");
	  	__update_text("-----------------------------------------------------------");
	  	$records_date[$file_index++]=$filename2;
	  	GetUsrDataFromFile("$main::dir\\$filename2");		
	  }
	  elsif($filename2 =~ /^$valid_order/)
	  {
	  	__update_text("-----------------------------------------------------------");
	  	__update_text("处理文件：$filename2");
	  	__update_text("-----------------------------------------------------------");
	  	GetTradeDataFromFile("$main::dir\\$filename2");	  	
	  	
	  }   
     $filename2=pop(@file_array2);	
   }
	

   __update_text("提取信息完成！！");	
   
   __update_text("分析中...");
   GetTradeDataByServer();
   __update_text("分析完成！！");

   my $customerreqcount=keys %customerreq;
   __update_text("-----------------------------------------------------------");
   __update_text("客户请求总数：$customerreqcount"); 
   __update_text("-----------------------------------------------------------"); 
        
   my $reqindex=1;     	
   while((my $key, my $value) = each %customerreq)
   {
       if($main::state ==0)
       {
     	 return;
       }
       #__update_text("$reqindex.$key");
       $reqindex++;	       
       #chomp $value;
       my @buf=split(/\|/,$key);
       my $count=0;
       while ($count < @server_name_list) 
       {
       	 if($buf[2] eq $server_name_list[$count])
       	 {
       	 	$handlecount[$count]++;
       	 	last;
       	 }
	 $count++;
       }
       	my $count2=0;
	while ($count2<@customername_list)
	{
	   if($main::state ==0)
           {
     	           return;
           }		   
	   if($buf[1] eq $customername_list[$count2])
	   {

	   	$customer_req_times[$count2]++;		   	
	   	last;
	   }
	   $count2++;	
		
	}	       
	
   }
   __update_text("-----------------------------------------------------------");
   my $index=0;
   while ($index<@server_name_list)
   {
   	  if($main::state ==0)
          {
     	     return;
          }
	  if(defined $handlecount[$index])
	  {
		  __update_text("$server_name_list[$index]处理：$handlecount[$index]个");		 			
	  }
	  else
	  {
	  	  $handlecount[$index]=0;
	  	  __update_text("$server_name_list[$index]处理：$handlecount[$index]个");
	  }	  
	   $index++;
	  	
   }
   __update_text("-----------------------------------------------------------");
	
   __update_text("交互次数超过一次的客户详情："); 
   my $index2=0;
   my $index3=1;
   my $index4=1;
   while ($index2<@customername_list)
   {
      if($main::state ==0)
      {
     	 return;
      }
      if(defined $customer_req_times[$index2])	
      {
          if($customer_req_times[$index2]>1)
          {
          	__update_text("$index4.客户:$customername_list[$index2],交互次数:$customer_req_times[$index2]天");
          	while((my $key, my $value) = each %customerreq)
          	{
          	  if($main::state ==0)
                  {
     	             return;
                  }
          	  my @buf2=split(/\|/,$key);
          	  if($buf2[1] eq $customername_list[$index2])
          	  {
          	  	#__update_text("        $index3.时间:$buf2[0],客服:$value");
          	  	$index3++;
          	  }	
          		
          	}
          	$index4++;	          	
          		          	
          }	  	
      }	  
	
      $index2++;			
   }
   __update_text("-----------------------------------------------------------");
   if($main::state ==0)
   {
     return;
   }	
   GenerateReport();
   GenerateTradeReport();
   __update_text("生成报表如下：");
   __update_text_decode("$report_file_handle");
   __update_text_decode("$report_excel_handle");
   
			
   $main::state=0;
 	
}


sub GenerateReport
{
  my $index1=0;
  my $index2=0;
  my $index3=0;
  WriteToReport("\n-----------------------------------------------------------");
  @records_date=sort(@records_date);
  my $len=@records_date;
  my @date_begin=split(/\./,$records_date[0]);
  my @date_final=split(/\./,$records_date[$len-1]);
  WriteToReport("\n[From: $date_begin[0] To:$date_final[0]]");

  WriteToReport("\n[Number of customer service is:$server_num]");
  
  while($index1 < $server_num)
  {
     if($main::state ==0)
     {
     	return;
     }
     $index1++; 
     WriteToReport("\n $index1.$server_name_list[$index1 -1]"); 
	
  }  

  
  WriteToReport("\n[Number of customer is:$customercount]");
  
  while($index2 < $customercount)
  {
     if($main::state ==0)
     {
     	return;
     }
     $index2++; 
     WriteToReport("\n $index2.$customername_list[$index2 -1]"); 
	
  }    
 
  WriteToReport("\n[Detailed Allocation]");
  
  while ($index3<@server_name_list)
  {
     if($main::state ==0)
     {
     	return;
     }
    if(defined $handlecount[$index3])
    {
	  WriteToReport("\n $server_name_list[$index3] 处理：$handlecount[$index3]个");		 			
    }
    else
    {
  	  $handlecount[$index3]=0;
  	  WriteToReport("\n $server_name_list[$index3] 处理：$handlecount[$index3]个");
    }	  
    $index3++;
  	
  }
  WriteToReport("\n-----------------------------------------------------------");

}


1;