clear;clc
Upolicy(1:9,:)=ones(9,10);
Upolicy(10:11,:)=zeros(2,10);
NUpolicy=Upolicy;
ep=6500000;
OptUpolicy=Upolicy;
ReverseUpolicy=OptUpolicy;
OptNUpolicy=NUpolicy;
ReverseNUpolicy=OptNUpolicy;
Dpolicy=[ones(1,16),zeros(1,5)];
CardValue=[1:10,10,10,10];
RecordUStick=zeros(size(OptUpolicy));
RecordNUStick=RecordUStick;
ActionUStick=RecordUStick;
ActionNUStick=ActionUStick;
RecordUHit=RecordUStick;
RecordNUHit=RecordUHit;
ActionUHit=RecordUHit;
ActionNUHit=ActionUHit;
for t=1:ep
    %% starting state generation
    clear PlayerAction PlayerState UsableAce PlayerBust PlayerCard
    clear DealerCard DealerBust DealerAce
    StartingState=randi(11);
    if(StartingState==11)
        UsableAce(1)=1;
        PlayerAction(1)=0;
    elseif(StartingState==1)
        UsableAce(1)=0;
        PlayerAction(1)=randi([0,1]);
    else
        UsableAce(1)=randi([0,1]);
        PlayerAction(1)=randi([0,1]);
    end
    DealerCard=randi(13,1,2);        
    DealerState=CardValue(DealerCard(1));
    m=1;
    PlayerState(m)=StartingState;
    PlayerBust=0;
    %% generate player episode
    while(PlayerAction(m))
        m=m+1;
        PlayerCard=randi(13);
        PlayerState(m)=PlayerState(m-1)+CardValue(PlayerCard);
        if(PlayerState(m)>11&&UsableAce(m-1))
            UsableAce(m)=0;
            PlayerBust=0;
            PlayerState(m)=PlayerState(m)-10;
        else
            UsableAce(m)=UsableAce(m-1);
        end
        if(~UsableAce(m)&&PlayerState(m)>11)
            PlayerAction(m)=0;
            PlayerBust=1;
        elseif(~UsableAce(m))
            PlayerAction(m)=OptNUpolicy(PlayerState(m),DealerState);
            PlayerBust=0;
        else
            PlayerAction(m)=OptUpolicy(PlayerState(m),DealerState);
            PlayerBust=0;
        end
    end
    %% generate dealer episode(dealer hit in soft 17)
    if (PlayerBust==1)
        DealerAction=0;
    else
        if(sum(DealerCard==1)&&sum(CardValue(DealerCard))>=8)
            DealerAction=0;
            DealerSum=10+sum(CardValue(DealerCard));
        elseif(sum(DealerCard==1))
            DealerAction=1;
            DealerSum=10+sum(CardValue(DealerCard));
            DealerAce=1;
        else
            DealerSum=sum(CardValue(DealerCard));
            DealerAction=Dpolicy(DealerSum);
            DealerAce=0;
        end
    end
    DealerBust=0;
    m=2;
    while(DealerAction)
       m=m+1;
       DealerCard(m)=randi(13);
       if(DealerCard(m)==1&&~DealerAce)
           DealerSum=DealerSum+CardValue(DealerCard(m))+10;
           DealerAce=1;
       else
           DealerSum=DealerSum+CardValue(DealerCard(m));
       end
       if(DealerAce&&DealerSum>21)
          DealerSum=DealerSum-10;
          DealerAce=0;
       end
       if(~DealerAce&&DealerSum>21)
           DealerAction=0;
           DealerBust=1;
       elseif(DealerAce&&DealerSum>=18)
           DealerAction=0;
       elseif(DealerAce)
           DealerAction=1;
       elseif(~DealerAce)
           DealerAction=Dpolicy(DealerSum);
       end
    end
    %% game result
    if(PlayerBust)
        R=-1;
    elseif(DealerBust)
        R=1;
    elseif(PlayerState(end)>(DealerSum-10))
        R=1;
    elseif(PlayerState(end)==(DealerSum-10))
        R=0;
    else
        R=-1;
    end
    if(length(PlayerAction)==1)
        m=1;
    elseif(PlayerAction(end)==0&&PlayerState(end)==11)
        m=length(PlayerAction);
    else
        m=length(PlayerAction)-1;
    end
    while(m)
        if(PlayerAction(m)&&UsableAce(m))
            ActionUHit(PlayerState(m),DealerState)=ActionUHit(PlayerState(m),DealerState)+1;
            RecordUHit(PlayerState(m),DealerState)=RecordUHit(PlayerState(m),DealerState)+(R-RecordUHit(PlayerState(m),DealerState))/ActionUHit(PlayerState(m),DealerState);
        elseif(PlayerAction(m)&&~UsableAce(m))
            ActionNUHit(PlayerState(m),DealerState)=ActionNUHit(PlayerState(m),DealerState)+1;
            RecordNUHit(PlayerState(m),DealerState)=RecordNUHit(PlayerState(m),DealerState)+(R-RecordNUHit(PlayerState(m),DealerState))/ActionNUHit(PlayerState(m),DealerState);
        elseif(~PlayerAction(m)&&UsableAce(m))
            ActionUStick(PlayerState(m),DealerState)=ActionUStick(PlayerState(m),DealerState)+1;
            RecordUStick(PlayerState(m),DealerState)=RecordUStick(PlayerState(m),DealerState)+(R-RecordUStick(PlayerState(m),DealerState))/ActionUStick(PlayerState(m),DealerState);
        else
            ActionNUStick(PlayerState(m),DealerState)=ActionNUStick(PlayerState(m),DealerState)+1;
            RecordNUStick(PlayerState(m),DealerState)=RecordNUStick(PlayerState(m),DealerState)+(R-RecordNUStick(PlayerState(m),DealerState))/ActionNUStick(PlayerState(m),DealerState);
        end
        m=m-1;
    end
    for m=2:10
        for n=1:10
            if(RecordNUHit(m,n)>RecordNUStick(m,n))
                OptNUpolicy(m,n)=1;
            elseif(RecordNUHit(m,n)<RecordNUStick(m,n))
                OptNUpolicy(m,n)=0;
            end
            if(RecordUHit(m,n)>RecordUStick(m,n))
                OptUpolicy(m,n)=1;
            elseif(RecordUHit(m,n)<RecordUStick(m,n))
                OptUpolicy(m,n)=0;
            end
        end
    end
end
for m=2:11
    for n=1:10
        UReward(m-1,n)=OptUpolicy(m,n)*RecordUHit(m,n)+(1-OptUpolicy(m,n))*RecordUStick(m,n);
        NUReward(m-1,n)=OptNUpolicy(m,n)*RecordNUHit(m,n)+(1-OptNUpolicy(m,n))*RecordNUStick(m,n);
    end
end
for m=1:11
    ReverseUpolicy(m,:)=OptUpolicy(12-m,:);
    ReverseNUpolicy(m,:)=OptNUpolicy(12-m,:);
end

figure(1)
clf;
mesh(UReward)
xlabel('Dealer showing')
ylabel('Player Sum')

figure(2)
heatmap(ReverseUpolicy,'GridVisible','off','ColorbarVisible','off')
xlabel('Dealer showing')
ylabel('Player Sum')

figure(3)
clf;
mesh(NUReward)
xlabel('Dealer showing')
ylabel('Player Sum')

figure(4)
heatmap(ReverseNUpolicy,'GridVisible','off','ColorbarVisible','off')
xlabel('Dealer showing')
ylabel('Player Sum')

    
