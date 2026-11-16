using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using MoldSign.App.Services;
using MoldSign.Core.Protection;
using MoldSign.Desktop;
using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;
using Windows.Storage.Pickers;

namespace MoldSign.App.Views;

internal sealed class FileProtectionDialog : ContentDialog
{
    private readonly IPasswordFileProcessor _processor;
    private readonly ComboBox _operation=new(){HorizontalAlignment=HorizontalAlignment.Stretch};
    private readonly ComboBox _method=new(){HorizontalAlignment=HorizontalAlignment.Stretch};
    private readonly ComboBox _identities=new(){HorizontalAlignment=HorizontalAlignment.Stretch,DisplayMemberPath="Label"};
    private readonly PasswordBox _password=new(),_confirmation=new(),_pin=new();
    private readonly TextBlock _file=new(){TextWrapping=TextWrapping.Wrap},_recipient=new(){TextWrapping=TextWrapping.Wrap},_notice=new(){TextWrapping=TextWrapping.Wrap};
    private readonly TextBlock _warning=new(){TextWrapping=TextWrapping.Wrap};
    private readonly CheckBox _removeConfirmation=new();
    private readonly Button _choose=new(),_chooseCertificate=new(),_readCard=new(),_exportCertificate=new();
    private readonly StackPanel _form=new(){Spacing=16};
    private readonly TextBlock _recipientSummary=new(){TextWrapping=TextWrapping.Wrap},_mismatch=new(){TextWrapping=TextWrapping.Wrap};
    private readonly TextBlock _guide=new(){TextWrapping=TextWrapping.Wrap},_helpText=new(){TextWrapping=TextWrapping.Wrap};
    private readonly Expander _help=new(){HorizontalAlignment=HorizontalAlignment.Stretch},_details=new(){HorizontalAlignment=HorizontalAlignment.Stretch};
    private string? _source,_reader;
    private X509Certificate2? _certificate;
    private byte[]? _output;
    private bool _busy;
    private bool _completed;
    public FileProtectionDialog(XamlRoot root,ElementTheme theme,int operation = 0, ProtectionPreview? preview = null, IPasswordFileProcessor? processor = null, string? initialSource = null)
    {
        _processor = processor ?? App.Current.Services.FileProtection;
        XamlRoot=root;RequestedTheme=theme;Title=Loc.Get("protect_title");CloseButtonText=Loc.Get("Action_Cancel");
        Content=new ScrollViewer {Content=_form,MaxHeight=660,MinWidth=400,HorizontalScrollBarVisibility=ScrollBarVisibility.Disabled};
        _operation.Header=Loc.Get("protect_operation");
        _method.Header=Loc.Get("protect_access_step");
        foreach(var key in new[]{"protect_encrypt","protect_decrypt","protect_remove"}) _operation.Items.Add(Loc.Get(key));
        _operation.SelectedIndex=operation;_form.Children.Add(_operation);
        _form.Children.Add(new TextBlock {Text=Loc.Get("protect_file_step")});
        _choose.Content=Loc.Get("protect_choose_file");_form.Children.Add(_choose);_form.Children.Add(_file);
        foreach(var key in new[]{"protect_password"}) _method.Items.Add(Loc.Get(key));
        _method.SelectedIndex=0;_form.Children.Add(_method);_form.Children.Add(_guide);
        _password.Header=Loc.Get("protect_password");_confirmation.Header=Loc.Get("protect_confirm_password");_pin.Header=Loc.Get("protect_card_pin");
        _form.Children.Add(_password);_form.Children.Add(_confirmation);
        _mismatch.Text=Loc.Get("protect_mismatch");_form.Children.Add(_mismatch);
        _chooseCertificate.Content=Loc.Get("protect_choose_certificate");_readCard.Content=Loc.Get("protect_read_card");
        _form.Children.Add(_chooseCertificate);_form.Children.Add(_readCard);_form.Children.Add(_identities);_form.Children.Add(_recipientSummary);_form.Children.Add(_pin);
        _exportCertificate.Content=Loc.Get("protect_export_certificate");
        var detailsContent=new StackPanel {Spacing=12};detailsContent.Children.Add(_recipient);detailsContent.Children.Add(_exportCertificate);
        detailsContent.Children.Add(new TextBlock {Text=Loc.Get("protect_export_certificate_hint"),TextWrapping=TextWrapping.Wrap});
        _details.Header=Loc.Get("protect_details");_details.Content=detailsContent;_form.Children.Add(_details);
        _help.Header=Loc.Get("protect_help");_help.Content=_helpText;_form.Children.Add(_help);
        _exportCertificate.Click+=async(_,_)=>{
            if(_identities.SelectedItem is not CardEncryptionIdentity identity)return;
            var bytes=identity.Certificate.ToArray();
            var picker=new FileSavePicker();picker.FileTypeChoices.Add("X.509 certificate",new List<string>{".cer"});picker.SuggestedFileName="encryption-"+identity.Fingerprint;
            WinRT.Interop.InitializeWithWindow.Initialize(picker,WindowHelpers.HandleFor(XamlRoot));
            SetBusy(true);
            try { var file=await picker.PickSaveFileAsync();if(file!=null){await Windows.Storage.FileIO.WriteBytesAsync(file,bytes);_notice.Text=Loc.Get("protect_saved");} }
            catch{Error();}finally{SetBusy(false);}
        };
        _form.Children.Add(_warning);_removeConfirmation.Content=Loc.Get("protect_remove_confirm");_form.Children.Add(_removeConfirmation);
        _form.Children.Add(_notice);
        DefaultButton=ContentDialogButton.Primary;
        _operation.SelectionChanged+=(_,_)=>ResetSelection();_method.SelectionChanged+=(_,_)=>ResetSelection();
        _password.PasswordChanged+=(_,_)=>SecretChanged();_confirmation.PasswordChanged+=(_,_)=>SecretChanged();_pin.PasswordChanged+=(_,_)=>SecretChanged();
        _removeConfirmation.Checked+=(_,_)=>Refresh();_removeConfirmation.Unchecked+=(_,_)=>Refresh();
        _identities.SelectionChanged+=(_,_)=>{
            if(_identities.SelectedItem is CardEncryptionIdentity identity) {
                _certificate?.Dispose();_certificate=X509CertificateLoader.LoadCertificate(identity.Certificate);
                _recipient.Text=_certificate.Subject+"\n"+identity.Fingerprint;_pin.Password="";ClearOutput();Refresh();
            }
        };
        _choose.Click+=async(_,_)=>{
            var paths=await WindowHelpers.PickFilesAsync(root.ContentIslandEnvironment.AppWindowId,"*");
            if(paths.Count==0)return;_source=paths[0];_file.Text=Path.GetFileName(_source);_removeConfirmation.IsChecked=false;ClearOutput();Refresh();
        };
        _chooseCertificate.Click+=async(_,_)=>{
            var paths=await WindowHelpers.PickFilesAsync(root.ContentIslandEnvironment.AppWindowId,"*");if(paths.Count==0)return;
            SetBusy(true);ClearOutput();
            try {
                var certificate=await Task.Run(()=>{
                    var bytes=ProtectedFileIO.Read(paths[0]);if(bytes.Length>65536)throw new IOException();
                    var cert=X509CertificateLoader.LoadCertificate(bytes);
                    try{CertificateFileProtection.Encrypt([],cert);return cert;}catch{cert.Dispose();throw;}
                });
                _certificate?.Dispose();_certificate=certificate;_identities.ItemsSource=null;_recipient.Text=certificate.Subject+"\n"+Convert.ToHexString(SHA256.HashData(certificate.RawData));
            }catch{Error();}finally{SetBusy(false);}
        };
        _readCard.Click+=async(_,_)=>{
            SetBusy(true);ClearOutput();_certificate?.Dispose();_certificate=null;_identities.ItemsSource=null;_recipient.Text="";_pin.Password="";
            try{
                if(App.Current.Services.IsDemo)throw new InvalidOperationException();
                _reader=AppState.Current.SelectedReader;if(_reader==null)throw new InvalidOperationException();
                var identities=await Task.Run(()=>App.Current.Services.Signing.EncryptionIdentities(_reader));
                _identities.ItemsSource=identities;_identities.SelectedIndex=identities.Count>0?0:-1;
                if(identities.Count==0)_notice.Text=Loc.Get("protect_no_key");
            }catch{Error();}finally{SetBusy(false);}
        };
        PrimaryButtonClick+=async(_,e)=>{e.Cancel=true;if(_busy)return;if(_output!=null)await Save();else await Process();};
        Closing+=(_,e)=>{if(_busy)e.Cancel=true;};
        Closed+=(_,_)=>{_password.Password="";_confirmation.Password="";_pin.Password="";ClearOutput();_certificate?.Dispose();};
        preview ??= ProtectionPreview.Selected;
        if (preview is not null)
        {
            _operation.SelectedIndex = (int)preview.Operation;
            _method.SelectedIndex = 0;
            _file.Text = preview.Filename;
        }
        if (initialSource is not null && File.Exists(initialSource)) { _source = initialSource; _file.Text = Path.GetFileName(initialSource); }
        Refresh();
    }
    private void SecretChanged(){if(!_busy)ClearOutput();Refresh();}
    private void ClearOutput(){_completed=false;if(_output!=null)CryptographicOperations.ZeroMemory(_output);_output=null;_notice.Text="";}
    private void ResetSelection(){ClearOutput();_password.Password="";_confirmation.Password="";_pin.Password="";_removeConfirmation.IsChecked=false;Refresh();}
    private void SetBusy(bool value){_busy=value;foreach(var control in _form.Children.OfType<Control>())control.IsEnabled=!value;IsPrimaryButtonEnabled=!value;Refresh();}
    private void Error()=>_notice.Text=Loc.Get("protect_error");
    private void Refresh(){
        var remove=_operation.SelectedIndex==2;var decrypt=_operation.SelectedIndex==1;var card=_method.SelectedIndex==1;
        static Visibility Visible(bool v)=>v?Visibility.Visible:Visibility.Collapsed;
        _method.Visibility=Visibility.Collapsed;_password.Visibility=Visible(!remove&&!card);_confirmation.Visibility=Visible(!remove&&!card&&!decrypt);
        _chooseCertificate.Visibility=Visible(!remove&&card&&!decrypt);_readCard.Visibility=Visible(!remove&&card);_identities.Visibility=Visible(!remove&&card&&_identities.Items.Count>1);
        _recipientSummary.Visibility=Visible(!remove&&card&&_certificate!=null);
        _recipientSummary.Text=_certificate?.GetNameInfo(X509NameType.SimpleName,false)??"";
        _mismatch.Visibility=Visible(!remove&&!card&&!decrypt&&_confirmation.Password.Length>0&&_password.Password!=_confirmation.Password);
        _details.Visibility=Visible(!remove&&card&&_certificate!=null);
        _guide.Visibility=Visible(!remove);_help.Visibility=Visible(!remove);
        var helpPrefix=card?"protect_certificate_":"protect_password_";
        helpPrefix+=decrypt?"decrypt":"encrypt";
        _guide.Text=Loc.Get(helpPrefix+"_guide");_helpText.Text=Loc.Get(helpPrefix+"_help")+"\n\n"+Loc.Get("protect_compatibility");
        _exportCertificate.Visibility=Visible(!remove&&card&&_identities.SelectedItem is CardEncryptionIdentity);
        _pin.Visibility=Visible(!remove&&card&&decrypt&&_identities.SelectedItem!=null);_removeConfirmation.Visibility=Visible(remove);
        _warning.Text=Loc.Get(remove?"protect_removal_warning":"protect_original");
        CloseButtonText=Loc.Get(_completed || _output!=null ? "saved_close" : "Action_Cancel");
        PrimaryButtonText=_completed ? "" : _output!=null?Loc.Get("protect_save_file"):Loc.Get(remove?"protect_remove":decrypt?"protect_decrypt":"protect_encrypt");
        IsPrimaryButtonEnabled=!_busy&&(_output!=null||_source!=null&&(remove?_removeConfirmation.IsChecked==true:card?(decrypt?_identities.SelectedItem!=null&&_pin.Password.Length>0:_certificate!=null):_password.Password.Length>0&&(decrypt||_password.Password==_confirmation.Password)));

    }
    private async Task Process(){
        if(_source==null)return;var source=_source;var operation=_operation.SelectedIndex;var card=_method.SelectedIndex==1;
        var password=_password.Password;var pin=_pin.Password;var certificate=_certificate;var identity=_identities.SelectedItem as CardEncryptionIdentity;
        SetBusy(true);ClearOutput();_password.Password="";_confirmation.Password="";_pin.Password="";
        try{
            _output=await Task.Run(()=>{
                if(!card || operation==2)
                    return _processor.Process(source, (FileProtectionOperation)operation, password);
                var bytes=ProtectedFileIO.Read(source);
                if(operation==0)return CertificateFileProtection.Encrypt(bytes,certificate??throw new InvalidOperationException());
                return App.Current.Services.Signing.DecryptFile(bytes,identity??throw new InvalidOperationException(),pin,_reader);
            });
            _notice.Text=Loc.Get(operation==2?"protect_removed":"protect_ready");_completed=operation==2;
            if(operation==2){_source=null;_file.Text="";}
        }catch{Error();}finally{password="";pin="";SetBusy(false);}
    }
    private async Task Save(){
        if(_output==null||_source==null)return;
        var picker=new FolderPicker();picker.FileTypeFilter.Add("*");WinRT.Interop.InitializeWithWindow.Initialize(picker,WindowHelpers.HandleFor(XamlRoot));
        var folder=await picker.PickSingleFolderAsync();if(folder==null)return;
        var name=Path.GetFileName(_source);
        if(_operation.SelectedIndex==0)name+=_method.SelectedIndex==0?PasswordFileProtection.Suffix:CertificateFileProtection.Suffix;
        else{foreach(var suffix in new[]{PasswordFileProtection.Suffix,CertificateFileProtection.Suffix})if(name.EndsWith(suffix,StringComparison.OrdinalIgnoreCase))name=name[..^suffix.Length];name="decrypted-"+name;}
        var destination=Path.Combine(folder.Path,name);SetBusy(true);
        try{await Task.Run(()=>ProtectedFileIO.SaveNew(destination,_output));ClearOutput();_completed=true;_notice.Text=Loc.Get("protect_saved");
            AppState.Current.AddActivity(new ActivityItem(Path.GetFileName(destination), Loc.Get(_operation.SelectedIndex==0 ? "protect_encrypted" : "protect_decrypted"), DateTimeOffset.Now, true, destination, SignedOutput:false, ProtectionOperation:_operation.SelectedIndex==0 ? "encrypted" : "decrypted"));}
        catch{Error();}finally{SetBusy(false);}
    }
}
