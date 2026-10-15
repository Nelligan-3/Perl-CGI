#!C:\Strawberry\perl\bin\perl.exe
require '../object/AccountObject.pl';
require '../service/AccountService_SQLite3.pl';
require '../object/ErrorTextObject.pl';
require '../service/ErrorTextService_SQLite3.pl';
use Template;
use CGI::Session;
use Crypt::URandom ();
use Crypt::Argon2 ();

package AccountAction;

sub new {
  my $class = shift;
  my $self = {
    _service => shift,
    _form => shift,
	_db => shift,
  };
  return bless $self, $class;
}

sub doExecute {
  my ($self) = @_;
  $self->{_form} = AccountObject->new(());
  if($self->{_form}->getSid() != 0) {
	$session = CGI::Session->new($self->{_form}->getSid());
  } else {
	$session = CGI::Session->new();
  }
  $self->{_service} = AccountService->new;
  if($self->{_form}->getAction() eq 'insert') {
       $self->doInsert();
  }elsif($self->{_form}->getAction() eq 'login'){
       $self->doLogin($session);
  }elsif($self->{_form}->getAction() eq 'logout'){
       $self->doLogout($session);
  }else{ 
       $self->doIndex();
  }
}

sub doIndex {
  my ($self) = @_;
  print "Content-Type: text/html\n\n";
  my $tt = Template->new({INCLUDE_PATH => '../templates'});
  $tt->process('index.htm', {lang => $self->{_form}->getLang()});
}

sub doInsert {
  my ($self) = @_;
  my $errortextService = ErrorTextService->new;
  my @len = $self->{_service}->retrieveAccount($self->{_form}->getAccountname());
  $found = @len;
  if($found == 0){
	  $self->{_service}->insert($self->{_form});
	  @errortexts = $errortextService->retrieveErrortext(2, $self->{_form}->getLang());
  } else {
	  @errortexts = $errortextService->retrieveErrortext(3, $self->{_form}->getLang());
  }
  $errortext = $errortexts[0]->getErrortext();
  print "Content-Type: text/html\n\n";
  my $tt = Template->new({INCLUDE_PATH => '../templates'});
  $tt->process('return.htm', {lang => $self->{_form}->getLang(), action => 'index', errortext => $errortext});
}

sub doLogin {
  my ($self) = @_;
  my $errortextService = ErrorTextService->new;
  @len = $self->{_service}->retrieveAccount($self->{_form}->getAccountname());
  $found = @len;
  if(($found > 0) && (Crypt::Argon2::argon2_verify($len[0]->getPassword(), $self->{_form}->getPassword()))){
	$CGIsessionID = $session->id();
	$session->param('lang', $self->{_form}->getLang());
	$session->param('accountId', $len[0]->getId());
	print "Location: ChannelAction.pl?hidAction=index&hidLang=" . $self->{_form}->getLang() . "&hidaccountId=" . $session->param('accountId') . "&hidSid=" . $CGIsessionID . "\n\n";
  } else {
    @errortexts = $errortextService->retrieveErrortext(1, $self->{_form}->getLang());
    $errortext = $errortexts[0]->getErrortext();
    print "Content-Type: text/html\n\n";
    my $tt = Template->new({INCLUDE_PATH => '../templates'});
    $tt->process('return.htm', {lang => $self->{_form}->getLang(), action => 'index', errortext => $errortext});
  }
}

sub doLogout {
  my ($self) = @_;
  $lang = $self->{_form}->getLang();
  #$lang = $session->param('lang');
  my $errortextService = ErrorTextService->new;
  @errortexts = $errortextService->retrieveErrortext(4, $lang);
  $errortext = $errortexts[0]->getErrortext();
  $session->delete();
  $session->flush();
  print "Content-Type: text/html\n\n";
  my $tt = Template->new({INCLUDE_PATH => '../templates'});
  $tt->process('return.htm', {lang => $lang, action => 'index', errortext => $errortext});
}
1;

my $accountAction = AccountAction->new;
$accountAction->doExecute();
