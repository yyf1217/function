function [ R ] = fun_TrainData( varargin )
%FUN_TRAINDATA �˴���ʾ�йش˺�����ժҪ
%   �˴���ʾ��ϸ˵��
%JerryShang��2017.11.17
%%%ʵ�ֺ������أ������ɲ�ͬ�ķֲ���ѵ������
%%'k':K�ֲ���
%%'g'��gauss,
%%'p'��generalized Pareto clutter,����gamma�����ĸ��ϸ�˹�ֲ�
str = varargin{1}; %%%�ж�Ҫʵ�ֵķֲ�����:
switch str
    case 'g'
        if varargin ~= 4
           error('Gauss�ֲ�ѵ�������������Ϊ4����g ѡ�����ʸ��ά����ѵ�����ݳ��ȣ�Э����'); 
        end
        R = fun_TrainData_gauss(N,L, M);
    case 'k'
        if varargin ~= 5
           error('K�ֲ�ѵ�������������Ϊ5����k ѡ�����ʸ��ά����ѵ�����ݳ��ȣ�Э����,��״����'); 
        end
        R = fun_TrainData_K( N,L, M, v);
    case 'p'
        if varargin <= 6
           error('IG�ֲ�ѵ�����������������6����p ѡ�����ʸ��ά����ѵ�����ݳ��ȣ�Э����,��״����,�߶Ȳ�����SIRPѡ��'); 
        end
        R = fun_TrainData_IGCC( N,L,M,lamda,mu,opt);
    otherwise
            error('����ֻ��3��');
end
end
