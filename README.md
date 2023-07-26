# VotingGambling

선택지에 투표하고 비율이 적은 쪽이 승리하며 베팅금액을 승리자들에게 분배되는 컨트랙트

![image](https://github.com/bchsol/VotingGambling/assets/31833394/0eda68de-d8f6-44b6-b60b-753b6404c45c) ![image](https://github.com/bchsol/VotingGambling/assets/31833394/92a979e5-89de-415b-8d2f-60b98245c18e)

(플레이스토어 국민투표어플 참고)

-------------------------------------------------------------------------------------------

Openzeppelin의 UUPSUpgradable 적용

스토리지 충돌을 해결하기 위해 EIP-1967 에서 슬롯을 랜덤 배정함 (keccak256(name) - 1)

로직 컨트랙트간의 스토리지 충돌이 존재하는데 상태 변수선언 순서에 주의해야함

생성자가 비활성화이므로 함수를 통해 변수 초기화를 해야됨
