#!/usr/bin/perl -w
# Taobao business Aid System
#Author-Robot Boy

our $splash;
BEGIN {
        require Tk::Splash;
        my $image="image/robotwindow.gif"; 
	my $width=434;
	my $height=268;
	my $title="hello";
	my $overrideredirect=1;
        $splash = Tk::Splash->Show($image, $width, $height, $title,
                                   $overrideredirect);
}
       
use Tk;
use Tk::Splash;
use Encode;
use Encode::CN;
use open IN=>':encoding("gb2312")';
use strict;
use TBAS;
use Cwd;

our $state=0;
my $repeat2;
our $moduledir=decode("gbk",getcwd);;

our $dir="$moduledir/records";
my $ver = "1.0.2";



print "Start GUI\n";	

#MainWindow
our $mw = MainWindow->new;
$mw->configure(-bg=>"#9AC0CD");
$mw->geometry("800x600+240+80");
$mw->resizable( 0, 0 );
my $titletxt=decode("gbk","机器人软件之淘宝商家辅助");
$mw->title("$titletxt");
$mw->Label(-text =>$titletxt,-font=>[-size=>24],-bg=>"#9AC0CD")->pack();


#menu
my $main_menu = $mw->Menu();
$mw->configure(-menu => $main_menu);
#file
my $file_menu = $main_menu->cascade(-label=>decode(("gbk"),"文件"), -underline => 0, -tearoff=>0);
$file_menu->command(-label=>decode(("gbk"),"打开路径..."), -underline=>0, -command =>\&choosetalkingfilepath);
$file_menu->command(-label=>decode(("gbk"),"退出"), -underline=>0, -command => sub{exit});
#config

#run
my $run_menu = $main_menu->cascade(-label=>decode(("gbk"),"运行"), -underline => 0, -tearoff=>0);
$run_menu->command(-label=>decode(("gbk"),"分析"), -underline=>0, -command =>\&parsefile);
$run_menu->command(-label=>decode(("gbk"),"停止"), -underline=>0, -command =>\&stopparsefile);
$run_menu->command(-label=>decode(("gbk"),"清除"), -underline=>0, -command => \&clearrecords);
$run_menu->command(-label=>decode(("gbk"),"重置"), -underline=>0, -command => \&resetrecords);
#help
my $help_menu = $main_menu->cascade(-label =>decode(("gbk"), "帮助"), -underline => 0, -tearoff => 0);
$help_menu->command(-label =>decode(("gbk"), "版本"), -underline => 0,-command => sub{$mw->messageBox(-message => decode(("gbk"),"版本: $ver"),-type => "ok")});
$help_menu->command(-label =>decode(("gbk"), "关于机器人软件"), -underline => 0, -command => \&show_about);

our  $txt = $mw->Scrolled(
        'Text',
        -background => 'white',
        -foreground => 'black',
        -height     => '30',
        -takefocus  => '0',
        -width      => '110',
        -scrollbars => 'oe'
    )->pack;


my $filetag=$mw->Label(-text =>decode(("gbk"),"当前处理:"),-bg=>"#9AC0CD")->place(-x => 10, -y =>480);
my $filelab=$mw->Label(-text => $dir,-bg=>"#9AC0CD")->place(-x => 70, -y =>480);

#shortcut
my $parsebutton = $mw->Button(-text => decode(("gbk"),"分析数据"),-relief=>"raised" ,-activeforeground => "#8B0000",-activebackground => "#43CD80", -command => \&parsefile)->place(-x => 400, -y =>500);
my $stopbutton = $mw->Button(-text =>decode(("gbk"), "停止分析"),-relief=>"raised" ,-activeforeground => "#8B0000",-activebackground => "#43CD80", -command => \&stopparsefile)->place(-x => 500, -y =>500);
my $clearbutton = $mw->Button(-text =>decode(("gbk"), "清除记录"),-relief=>"raised" ,-activeforeground => "#8B0000",-activebackground => "#43CD80", -command => \&clearrecords)->place(-x => 600, -y =>500);
my $resetbutton = $mw->Button(-text => decode(("gbk"),"重置"),-relief=>"raised" ,-activeforeground => "#8B0000",-activebackground => "#43CD80", -command => \&resetrecords)->place(-x => 700, -y =>500);

#notice!
my $noticetext=decode("gbk","工作时，请勿骚扰！");
$txt -> Insert("\n$noticetext\n ");
#sleep 2;
$splash->Destroy if($splash) ;



MainLoop;



sub choosetalkingfilepath
{
    my $tmp = $mw->chooseDirectory(-initialdir => '~',-title => 'choose a directory');
    if (!defined $tmp) {
        warn 'No directory selected';
        my $notice1=decode("gbk","没有选择文件夹！");
	$txt -> Insert("\n$notice1\n ");
	$dir=$notice1;
	$filelab->configure(-text => $dir);
    } else {
        warn "Selected $tmp";
        $dir=decode("gbk",$tmp);
        $filelab->configure(-text => $dir);
        my $notice2=decode("gbk","你选择的文件夹是:");
	$txt -> Insert("\n$notice2 $dir\n ");
   }
}

sub stopparsefile{

   $state=0;
   
}



sub parsefile{
        if($dir eq decode("gbk","没有选择文件夹！"))
        {
        	my $notice=decode("gbk","请选择聊天记录所在的文件夹！");
        	$txt -> Insert("\n$notice\n ");
        }
        else
        {
	        $repeat2 = $mw->after( 110 =>\&dothings );
	
        }
        	
}


sub dothings{

	my $notice=decode("gbk","开始分析!...");
	$txt -> Insert("\n$notice \n ");
	$state=1;


	TBAS::GetRecordsFiles();
    
	$notice=decode("gbk","分析结束!...");
	$txt -> Insert("\n$notice \n ");
	TBAS::InitVariables();
	$state = 0;

}

sub clearrecords
{

  $txt ->delete('1.0','end');

}

sub resetrecords
{
  $txt ->delete('1.0','end');	
  $state=0;
  $dir="$moduledir/records";
  $filelab->configure(-text => $dir);
  my $notice=decode("gbk","你选择的文件夹是：");
  $txt -> Insert("\n$notice $dir\n ");
  TBAS::InitVariables();	
	
}


sub show_about 
{
  my $help_win =$mw->Toplevel;
  $help_win->resizable( 0, 0 );
  $help_win->geometry("300x100+340+340");
  my $abouttext=decode(("gbk"),"关于机器人");
  $help_win->title("$abouttext");
  my $help_msg = decode(("gbk"),"机器人软件系列可以帮助您简化办公，提高效率!\n 详情请联系：lingtongshen\@gmail.com \n QQ:758616242 \n MSN:boytong1982\@hotmal.com");
  $help_win->Label(-text => $help_msg)->pack();
  $help_win->Button(-text => decode(("gbk"),"确定"), -command => [$help_win => 'destroy'])->pack();
}
