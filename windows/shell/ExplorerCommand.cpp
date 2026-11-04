#include <windows.h>
#include <shobjidl.h>
#include <shlwapi.h>
#include <string>
#include <atomic>

// Native Explorer command: selection only. Signing always happens in the application.
static HMODULE module;
static std::atomic<long> objects{0};
static const CLSID commandId = {0x8fcf322a,0x7a44,0x4ec5,{0xa4,0x93,0x0f,0x84,0xe7,0x65,0x21,0xb2}};
static const CLSID verifyId = {0xc87d3a25,0x7e1e,0x4510,{0xb3,0x66,0x5e,0x87,0xa8,0x39,0xac,0x01}};
class Command final : public IExplorerCommand {
    std::atomic<ULONG> refs{1};
    bool verify;
public:
    explicit Command(bool verifyAction) : verify(verifyAction) { ++objects; }
    ~Command() { --objects; }
    HRESULT STDMETHODCALLTYPE QueryInterface(REFIID id, void** out) override { if (!out) return E_POINTER; *out=nullptr; if(id==IID_IUnknown || id==IID_IExplorerCommand) { *out=static_cast<IExplorerCommand*>(this); AddRef(); return S_OK; } return E_NOINTERFACE; }
    ULONG STDMETHODCALLTYPE AddRef() override { return ++refs; }
    ULONG STDMETHODCALLTYPE Release() override { auto n=--refs; if(!n) delete this; return n; }
    HRESULT STDMETHODCALLTYPE GetTitle(IShellItemArray*, LPWSTR* out) override {
        wchar_t title[256]; if(!LoadStringW(module,verify ? 102 : 101,title,256)) return E_FAIL;
        return SHStrDupW(title, out);
    }
    HRESULT STDMETHODCALLTYPE GetIcon(IShellItemArray*, LPWSTR* out) override {
        if (!out) return E_POINTER;
        wchar_t path[32768]; auto length = GetModuleFileNameW(module, path, 32768);
        if (!length || length >= 32768) return E_FAIL;
        std::wstring icon = std::wstring(path) + (verify ? L",-202" : L",-201");
        return SHStrDupW(icon.c_str(), out);
    }
    HRESULT STDMETHODCALLTYPE GetToolTip(IShellItemArray*, LPWSTR* out) override { if(out) *out=nullptr; return E_NOTIMPL; }
    HRESULT STDMETHODCALLTYPE GetCanonicalName(GUID* out) override { if(!out) return E_POINTER; *out=verify ? verifyId : commandId; return S_OK; }
    HRESULT STDMETHODCALLTYPE GetState(IShellItemArray* selection, BOOL, EXPCMDSTATE* state) override { if(!state) return E_POINTER; DWORD count=0; *state=selection && SUCCEEDED(selection->GetCount(&count)) && count ? ECS_ENABLED : ECS_HIDDEN; return S_OK; }
    HRESULT STDMETHODCALLTYPE Invoke(IShellItemArray* selection, IBindCtx*) override {
        if(!selection) return E_INVALIDARG;
        wchar_t location[32768]; auto length=GetModuleFileNameW(module,location,32768); if(!length || length>=32768) return E_FAIL;
        std::wstring path(location); path.resize(path.find_last_of(L"\\/")+1); path+=L"eSemnBun.exe";
        DWORD count=0; HRESULT hr=selection->GetCount(&count); if(FAILED(hr)) return hr;
        std::wstring args=verify ? L"--verify" : L"--sign";
        for(DWORD i=0;i<count;++i) { IShellItem* item=nullptr; if(FAILED(selection->GetItemAt(i,&item))) return E_FAIL; PWSTR file=nullptr; hr=item->GetDisplayName(SIGDN_FILESYSPATH,&file); item->Release(); if(FAILED(hr)) return hr;
            args+=L" \""; args+=file; args+=L"\""; CoTaskMemFree(file);
        }
        auto result=ShellExecuteW(nullptr,L"open",path.c_str(),args.c_str(),nullptr,SW_SHOWNORMAL);
        return reinterpret_cast<INT_PTR>(result)>32 ? S_OK : E_FAIL;
    }
    HRESULT STDMETHODCALLTYPE GetFlags(EXPCMDFLAGS* flags) override { if(!flags) return E_POINTER; *flags=ECF_DEFAULT; return S_OK; }
    HRESULT STDMETHODCALLTYPE EnumSubCommands(IEnumExplorerCommand** out) override { if(out) *out=nullptr; return E_NOTIMPL; }
};
class Factory final : public IClassFactory {
    std::atomic<ULONG> refs{1};
    bool verify;
public:
    explicit Factory(bool verifyAction):verify(verifyAction){++objects;} ~Factory(){--objects;}
    HRESULT STDMETHODCALLTYPE QueryInterface(REFIID id,void** out) override { if(!out)return E_POINTER; *out=nullptr; if(id==IID_IUnknown||id==IID_IClassFactory){*out=static_cast<IClassFactory*>(this);AddRef();return S_OK;}return E_NOINTERFACE; }
    ULONG STDMETHODCALLTYPE AddRef() override{return ++refs;}
    ULONG STDMETHODCALLTYPE Release() override{auto n=--refs;if(!n)delete this;return n;}
    HRESULT STDMETHODCALLTYPE CreateInstance(IUnknown* outer,REFIID id,void** out) override{if(outer)return CLASS_E_NOAGGREGATION;auto c=new Command(verify);auto hr=c->QueryInterface(id,out);c->Release();return hr;}
    HRESULT STDMETHODCALLTYPE LockServer(BOOL lock) override{lock ? ++objects : --objects;return S_OK;}
};
extern "C" HRESULT __stdcall DllGetClassObject(REFCLSID id,REFIID iid,void** out){if(id!=commandId && id!=verifyId)return CLASS_E_CLASSNOTAVAILABLE;auto f=new Factory(id==verifyId);auto hr=f->QueryInterface(iid,out);f->Release();return hr;}
extern "C" HRESULT __stdcall DllCanUnloadNow(){return objects==0 ? S_OK:S_FALSE;}
BOOL WINAPI DllMain(HINSTANCE instance,DWORD reason,LPVOID){if(reason==DLL_PROCESS_ATTACH){module=instance;DisableThreadLibraryCalls(instance);}return TRUE;}
