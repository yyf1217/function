%%%实现一个基于色加载的GLRT检测器
%%%%用化简后的公式
%%%基于MAM模型的用信息几何中的一种度量方式获得权值的协方差估计方法
clc
clear 
close all
%%%%参数设置
n = 1; %几倍的样本
str_train = 'p';%%训练数据分布，p:IG纹理复合高斯，k：k分布，g：gauss
lambda = 2;
mu = 1;
opt_train = 1; %%%IG的选项，1为每个距离单元IG纹理都不同
sigma_t = 1;
rou = 0.95;  %%协方差矩阵生成的迟滞因子
rouM=[0.5,0.6,0.945];%%%%%%%%%MAM模型
%%%Pd_CLGLRT_2Kmu1lambda3s0.1o1_p：2K：训练单元数目，mu，lambda，s：失配向量方差，
%%o1:opt=1，p：IG纹理复合高斯
%%%%假设参数设置
Na = 2;     % 阵元数
Np = 4;     % 脉冲数
N = Na*Np;
SNRout=-5:1:25; % 输出SNR
cos2=0.9;
PFA=1e-3;% PFA=1e-4;
SNRnum=10.^(SNRout/10);
MonteCarloPfa=1/PFA*100;
MonteCarloPd=1e4;
rouR = zeros(N,N);  %%真实的杂波协方差
L=round(n*N); 
theta_sig = 0.1;
nn = 0:N-1;
s = exp(-1i*2*pi*nn*theta_sig)'; %%%%%% 系统导向矢量
MAM = fun_rho(rouM,N);
rouR = fun_rho(rou,N);
rouR_abs=abs(rouR);
rouR_half=rouR^0.5;
irouR=inv(rouR);
%%%%导向矢量设置
% [UU,SS,VV]=svd(irouR*s);
% s_v=UU(:,2); %%%%%% 与vt在白化空间正交，即：s^H*iR*s_v==0
% weight=linspace(0,1,300);
% for i=1:length(weight)
%     s_tmpt=weight(i)*s+(1-weight(i))*s_v;
%     cos2_tmpt(i)=abs(s_tmpt'*irouR*s).^2/abs(s_tmpt'*irouR*s_tmpt*s'*irouR*s);
% end
% [Min, Index]=min(abs(cos2-cos2_tmpt));
% Weight=weight(Index);
% s_real=Weight*s+(1-Weight)*s_v;
% figure;plot(abs(s_real))
% figure; plot(weight,cos2_tmpt);
%%%%%正式开始%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%门限计算%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% h = waitbar(0,'Please wait...');
tic
parfor i = 1:MonteCarloPfa
    warning('off')
%     warning('query')
%     waitbar(i/MonteCarloPfa,h,sprintf([num2str(i/MonteCarloPfa*100),'%%']));
%%%%%%%%%%%训练数据产生%%%%%%%%%%%%%%
    Train = fun_TrainData(str_train,N,L,rouR,lambda,mu,opt_train);%%产生的训练数据,协方差矩阵为rouR的高斯杂波
    x0 = fun_TrainData(str_train,N,1,rouR,lambda,mu,opt_train); % 接收信号仅包括杂波和噪声
    %%%%协方差估计%%%%%%%%%%%%%%%%%%%%%%
    R_SCM = (fun_SCM(Train));
    
    R_SCMN = (fun_SCMN(Train));
    
    R_NSCM = (fun_NSCM(Train));
    
    R_NSCMN = (fun_NSCMN(Train));
    %%%%%%%MAM协方差估计%%%%%%%%%%%%%
    Rx0=fun_SCM(x0);
    R_MAM_r = fun_information_estimation(R_NSCMN,MAM,'r');
%     R_MAM_c = fun_information_estimation(Rx0,MAM,'c');
    R_MAM_e = fun_information_estimation(R_NSCMN,MAM,'e');
    R_MAM_l = fun_information_estimation(R_NSCMN,MAM,'l');
    R_MAM_p = fun_information_estimation(R_NSCMN,MAM,'p');
    R_MAM_ro = fun_information_estimation(R_NSCMN,MAM,'ro');
    %%%检测器%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%% ANMF_SCM
    Tanmf_SCM(i) = fun_ANMF(R_SCM,x0,s);
    %%%%%% ANMF_NSCM
    Tanmf_NSCM(i) = fun_ANMF(R_NSCM,x0,s);
    %%%%%% ANMF_MAM_r
    Tanmf_MAM_r(i) = fun_ANMF(R_MAM_r,x0,s);
    %%%%%% ANMF_MAM_c
%     Tanmf_MAM_c(i) = fun_ANMF(R_MAM_c,x0,s);
    %%%%%% ANMF_MAM_e
    Tanmf_MAM_e(i) = fun_ANMF(R_MAM_e,x0,s);
    %%%%%% ANMF_MAM_l
    Tanmf_MAM_l(i) = fun_ANMF(R_MAM_l,x0,s);
    %%%%%% ANMF_MAM_p
    Tanmf_MAM_p(i) = fun_ANMF(R_MAM_p,x0,s);
    %%%%%% ANMF_MAM_ro
    Tanmf_MAM_ro(i) = fun_ANMF(R_MAM_ro,x0,s);
    %%%%%% GLRT_MAM
    Tglrt_mam(i) = fun_MAM_GLRT(MAM,x0,s);
end
toc
% close(h)
TANMF_SCM=sort(Tanmf_SCM,'descend');
TANMF_NSCM=sort(Tanmf_NSCM,'descend');
TANMF_MAM_r=sort(Tanmf_MAM_r,'descend');
% TANMF_MAM_c=sort(Tanmf_MAM_c,'descend');
TANMF_MAM_e=sort(Tanmf_MAM_e,'descend');
TANMF_MAM_l=sort(Tanmf_MAM_l,'descend');
TANMF_MAM_p=sort(Tanmf_MAM_p,'descend');
TANMF_MAM_ro=sort(Tanmf_MAM_ro,'descend');
TGLRT_MAM=sort(Tglrt_mam,'descend');

Th_SCM=(TANMF_SCM(floor(MonteCarloPfa*PFA-1))+TANMF_SCM(floor(MonteCarloPfa*PFA)))/2;
Th_NSCM=(TANMF_NSCM(floor(MonteCarloPfa*PFA-1))+TANMF_NSCM(floor(MonteCarloPfa*PFA)))/2;

Th_MAM_r=(TANMF_MAM_r(floor(MonteCarloPfa*PFA-1))+TANMF_MAM_r(floor(MonteCarloPfa*PFA)))/2;
% Th_MAM_c=(TANMF_MAM_c(floor(MonteCarloPfa*PFA-1))+TANMF_MAM_c(floor(MonteCarloPfa*PFA)))/2;
Th_MAM_e=(TANMF_MAM_e(floor(MonteCarloPfa*PFA-1))+TANMF_MAM_e(floor(MonteCarloPfa*PFA)))/2;
Th_MAM_l=(TANMF_MAM_l(floor(MonteCarloPfa*PFA-1))+TANMF_MAM_l(floor(MonteCarloPfa*PFA)))/2;
Th_MAM_p=(TANMF_MAM_p(floor(MonteCarloPfa*PFA-1))+TANMF_MAM_p(floor(MonteCarloPfa*PFA)))/2;
Th_MAM_ro=(TANMF_MAM_ro(floor(MonteCarloPfa*PFA-1))+TANMF_MAM_ro(floor(MonteCarloPfa*PFA)))/2;

Th_GLRTMAM=(TGLRT_MAM(floor(MonteCarloPfa*PFA-1))+TGLRT_MAM(floor(MonteCarloPfa*PFA)))/2;
%%%%%%%%%%%%%%%%%%%%%检测概率%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
counter_scm=0;
counter_nscm=0;
counter_mam_r=0;
% counter_mam_c=0;
counter_mam_e=0;
counter_mam_l=0;
counter_mam_p=0;
counter_mam_ro=0;
counter_glrtmam=0;

Pd_SCM_mc = zeros(1,length(SNRout));
Pd_NSCM_mc = zeros(1,length(SNRout));
Pd_MAM_r_mc = zeros(1,length(SNRout));
% Pd_MAM_c_mc = zeros(1,length(SNRout));
Pd_MAM_e_mc = zeros(1,length(SNRout));
Pd_MAM_l_mc = zeros(1,length(SNRout));
Pd_MAM_p_mc = zeros(1,length(SNRout));
Pd_MAM_ro_mc = zeros(1,length(SNRout));
Pd_GLRTMAM_mc = zeros(1,length(SNRout));
% alpha=sqrt(SNRnum/abs(s_real'*irouR*s_real)); % 根据SNR=|alpha|^2*s'*R^(-1)*s求得|alpha|
alpha=sqrt(SNRnum/abs(s'*irouR*s)); % 根据SNR=|alpha|^2*s'*R^(-1)*s求得|alpha|
h = waitbar(0,'Please wait...');
tic
for m=1:length(SNRout)
    waitbar(m/length(SNRout),h,sprintf([num2str(m/length(SNRout)*100),'%%']));
    parfor i=1:MonteCarloPd
        %%%%%%%%%%%训练数据产生%%%%%%%%%%%%%%
        Train = fun_TrainData(str_train,N,L,rouR,lambda,mu,opt_train);%%产生的训练数据,协方差矩阵为rouR的高斯杂波
        x0 = fun_TrainData(str_train,N,1,rouR,lambda,mu,opt_train); % 接收信号仅包括杂波和噪声
        %%%%协方差估计%%%%%%%%%%%%%%%%%%%%%%
        R_SCM = (fun_SCM(Train));
    
        R_SCMN = (fun_SCMN(Train));
    
        R_NSCM = (fun_NSCM(Train));
    
        R_NSCMN = (fun_NSCMN(Train));
        %%%%%%%MAM协方差估计%%%%%%%%%%%%%
        Rx0=fun_SCM(x0);
        R_MAM_r = fun_information_estimation(R_NSCMN,MAM,'r');
%         R_MAM_c = fun_information_estimation(Rx0,MAM,'c');
        R_MAM_e = fun_information_estimation(R_NSCMN,MAM,'e');
        R_MAM_l = fun_information_estimation(R_NSCMN,MAM,'l');
        R_MAM_p = fun_information_estimation(R_NSCMN,MAM,'p');
        R_MAM_ro = fun_information_estimation(R_NSCMN,MAM,'ro');
        %%%检测信号
        x0=alpha(m)*s+x0;%+pp;    %%%%%%%  重要  %%%%%%%%%%%%%
        %%%检测器%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%% ANMF_SCM
        Tscm = fun_ANMF(R_SCM,x0,s);
        %%%%%% ANMF_NSCM
        Tnscm = fun_ANMF(R_NSCM,x0,s);
        %%%%%% ANMF_MAM_r
        Tmam_r = fun_ANMF(R_MAM_r,x0,s);
        %%%%%% ANMF_MAM_c
%         Tmam_c = fun_ANMF(R_MAM_c,x0,s);
        %%%%%% ANMF_MAM_e
        Tmam_e = fun_ANMF(R_MAM_e,x0,s);
        %%%%%% ANMF_MAM_l
        Tmam_l = fun_ANMF(R_MAM_l,x0,s);
        %%%%%% ANMF_MAM_p
        Tmam_p = fun_ANMF(R_MAM_p,x0,s);
        %%%%%% ANMF_MAM_ro
        Tmam_ro = fun_ANMF(R_MAM_ro,x0,s);
        %%%%%% GLRT_MAM
        Tglrtmam = fun_MAM_GLRT(MAM,x0,s);
        %%%判断%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
        if Tscm>Th_SCM;          counter_scm=counter_scm+1;        end                
        if Tnscm>Th_NSCM;       counter_nscm=counter_nscm+1;    end   
        if Tmam_r>Th_MAM_r;      counter_mam_r=counter_mam_r+1;    end
%         if Tmam_c>Th_MAM_c;      counter_mam_c=counter_mam_c+1;    end
        if Tmam_e>Th_MAM_e;      counter_mam_e=counter_mam_e+1;    end
        if Tmam_l>Th_MAM_l;      counter_mam_l=counter_mam_l+1;    end
        if Tmam_p>Th_MAM_p;      counter_mam_p=counter_mam_p+1;    end
        if Tmam_ro>Th_MAM_ro;      counter_mam_ro=counter_mam_ro+1;    end
        if Tglrtmam>Th_GLRTMAM;      counter_glrtmam=counter_glrtmam+1;    end
    end
    Pd_SCM_mc(m)=counter_scm/MonteCarloPd;           counter_scm=0;
    Pd_NSCM_mc(m)=counter_nscm/MonteCarloPd;        counter_nscm=0;
    Pd_MAM_r_mc(m)=counter_mam_r/MonteCarloPd;       counter_mam_r=0; 
%     Pd_MAM_c_mc(m)=counter_mam_c/MonteCarloPd;       counter_mam_c=0;
    Pd_MAM_e_mc(m)=counter_mam_e/MonteCarloPd;       counter_mam_e=0;
    Pd_MAM_l_mc(m)=counter_mam_l/MonteCarloPd;       counter_mam_l=0;
    Pd_MAM_p_mc(m)=counter_mam_p/MonteCarloPd;       counter_mam_p=0;
    Pd_MAM_ro_mc(m)=counter_mam_ro/MonteCarloPd;       counter_mam_ro=0;
    Pd_GLRTMAM_mc(m)=counter_glrtmam/MonteCarloPd;       counter_glrtmam=0; 
end
close(h)
toc
figure(1);
hold on
plot(SNRout,Pd_SCM_mc,'b-+','linewidth',2)
plot(SNRout,Pd_NSCM_mc,'k.-','linewidth',2)
plot(SNRout,Pd_MAM_r_mc,'g-s','linewidth',2)
% plot(SNRout,Pd_MAM_c_mc,'k-s','linewidth',2)
plot(SNRout,Pd_MAM_e_mc,'m-s','linewidth',2)
plot(SNRout,Pd_MAM_l_mc,'r-s','linewidth',2)
plot(SNRout,Pd_MAM_p_mc,'c-s','linewidth',2)
plot(SNRout,Pd_MAM_ro_mc,'b-s','linewidth',2)
plot(SNRout,Pd_GLRTMAM_mc,'y-o','linewidth',2)
h_leg = legend('ANMF with SCM','ANMF with NSCM','ANMF with MAM__r',...
    'ANMF with MAM__e','ANMF with MAM__l',...
    'ANMF with MAM__p','ANMF with MAM__o','GLRT with MAM');
xlabel('SNR/dB','FontSize',20)
ylabel('Pd','FontSize',20)
set(gca,'FontSize',20)
set(h_leg,'Location','SouthEast')
grid on
% str=['Pd_MAM_',num2str(n),'K','_',str_train,'.mat'];
% save(str,'SNRout','Pd_SCM_mc','Pd_NSCM_mc',...
%          'Pd_MAM_mc');
