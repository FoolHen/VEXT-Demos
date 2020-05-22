class 'Round'

RoundState = {
	WaitingForPlayers = 0,
	PreRound = 1,
	Running = 2,
	RoundOver = 3
}

local UPDATE_RATE = 0.5
local DEFAULT_MIN_PLAYERS = 2

function Round:__init(roundTime, minPlayers, preRoundTime, roundOverTime, announceInChat)
	Events:Subscribe('Engine:Update', self, self._onUpdate)
	Events:Subscribe('Player:Destroyed', self, self._onPlayerDestroyed)

	NetEvents:Subscribe('Round:PlayerReady', self, self._onPlayerReady)

	self._minPlayers = minPlayers or DEFAULT_MIN_PLAYERS
	self._announceInChat = announceInChat or true
	self._roundState = RoundState.WaitingForPlayers
	self._accumulatedDelta = 0

	self._maxPreRoundTime = preRoundTime or 0 -- No preround by default.
	self._maxRoundOverTime = roundOverTime or -1 -- Infinite roundover time by default.
	self._maxRoundTime = roundTime

	self._playersReady = {}

	self:_resetVars()
end

function Round:_resetVars()
	self._currentRoundTime = 0
	self._currentRoundOverTime = 0
	self._currentPreRoundTime = 0
end

function Round:getPlayersReady()
	return self._playersReady
end

function Round:getRoundState()
	return self._roundState
end

function Round:startPreRound()
	self:_setRoundState(RoundState.PreRound)
end

function Round:startRound()
	self:_setRoundState(RoundState.Running)
end

function Round:endRound()
	self:_setRoundState(RoundState.RoundOver)
end

function Round:_onPlayerReady(player)
	print('player '..player.name..' ready')
	table.insert(self._playersReady, player.guid)
end

function Round:_onPlayerDestroyed(player)
	for i, playerGuid in pairs(self._playersReady) do
		if playerGuid == player.guid then
			table.remove(self._playersReady, i)
			return
		end
	end
end

function Round:_numOfPlayersReady()
	local n = 0
	for _, __ in pairs(self._playersReady) do
		n = n + 1
	end
	return n
end


function Round:_onUpdate(delta, simulationDelta)
	self._accumulatedDelta = self._accumulatedDelta + delta

	if self._accumulatedDelta < UPDATE_RATE then
		return
	end

	-- If the game state is in waiting for players
	if self._roundState == RoundState.WaitingForPlayers then
		self:_onWaitingForPlayers()
	end

	-- If the game state is in preround
	if self._roundState == RoundState.PreRound then
		self:_onPreRound(self._accumulatedDelta)
	end
	
	-- If the game state is running
	if self._roundState == RoundState.Running then
		self:_onRunning(self._accumulatedDelta)
	end
	
	-- If the game state is in game over
	if self._roundState == RoundState.RoundOver then
		self:_onRoundOver(self._accumulatedDelta)
	end

	self._accumulatedDelta = 0
end

function Round:_onWaitingForPlayers()
	if self._roundState ~= RoundState.WaitingForPlayers then
		return
	end

	local playerCount = self:_numOfPlayersReady()

	if playerCount >= self._minPlayers then
		-- Skip preround if the max time is 0.
		if self._maxPreRoundTime == 0 then
			self:_setRoundState(RoundState.Running)
		else
			self:_setRoundState(RoundState.PreRound)
		end
	end
end

function Round:_onPreRound(delta)
	if self._roundState ~= RoundState.PreRound then
		return
	end

	local playerCount = self:_numOfPlayersReady()

	-- Min players condition not reached.
	if playerCount < self._minPlayers then
		self:_setRoundState(RoundState.WaitingForPlayers)
		return
	end

	-- Ignore if preround is infinite.
	if self._maxPreRoundTime < 0 then
		return
	end

	-- Time Expires.
	if self._currentPreRoundTime >= self._maxPreRoundTime then
		self:_setRoundState(RoundState.Running)
		return
	end

	self._currentPreRoundTime = math.min(self._currentPreRoundTime + delta, self._maxPreRoundTime)

	-- Check every second to announce how many seconds are left.
	if self._currentPreRoundTime - math.floor(self._currentPreRoundTime) < UPDATE_RATE then
		ChatManager:SendMessage('Round starts in ' .. math.ceil((self._maxPreRoundTime - self._currentPreRoundTime)))
	end

	-- print('Preround time: '..self._currentPreRoundTime)
end

function Round:_onRunning(delta)
	if self._roundState ~= RoundState.Running then
		return
	end

	local playerCount = self:_numOfPlayersReady()

	-- Min players condition not reached.
	if playerCount < self._minPlayers then
		self:_setRoundState(RoundState.WaitingForPlayers)
		return
	end

	-- Ignore if round is infinite.
	if self._maxPreRoundTime < 0 then
		return
	end
	
	-- Time Expires.
	if self._currentRoundTime >= self._maxRoundTime then
		self:_setRoundState(RoundState.RoundOver)
		return
	end

	-- Check every minute to announce how many minutes are left.
	if self._currentRoundTime % 60 <= UPDATE_RATE and self._currentRoundTime ~= 0 and self._announceInChat then
		ChatManager:SendMessage(math.ceil((self._maxRoundTime - self._currentRoundTime)/60) .. ' minutes left.')
	end
	
	-- Tick the current round time forward.
	self._currentRoundTime = math.min(self._currentRoundTime + delta, self._maxRoundTime)
	-- print('Round time: '..self._currentRoundTime)
	Events:Dispatch('Round:Time', math.floor(self._currentRoundTime))
end

function Round:_onRoundOver(delta)
	if self._roundState ~= RoundState.RoundOver then
		return
	end

	-- Ignore if roundover is infinite.
	if self._maxRoundOverTime < 0 then
		return
	end

	-- Time Expires, restart round.
	if self._currentRoundOverTime >= self._maxRoundOverTime then
		-- Skip preround if the max time is 0.
		if self._maxPreRoundTime == 0 then
			self:_setRoundState(RoundState.Running)
		else
			self:_setRoundState(RoundState.PreRound)
		end
		return
	end

	self._currentRoundOverTime = math.min(self._currentRoundOverTime + delta, self._maxRoundOverTime)
	-- print('Round over time: '..self._currentRoundOverTime)
end

function Round:_setRoundState(state)
	self:_resetVars()
	self._roundState = state

	local announceMessage

	if self._roundState == RoundState.WaitingForPlayers then
		Events:Dispatch('Round:WaitingForPlayers')
		announceMessage = 'Round stopped. Waiting for more players.'
	elseif self._roundState == RoundState.PreRound then
		Events:Dispatch('Round:PreRoundStart')
		announceMessage = 'Preround started.'
	elseif self._roundState == RoundState.Running then
		Events:Dispatch('Round:RoundStart')
		announceMessage = 'Round started.'
	elseif self._roundState == RoundState.RoundOver then
		Events:Dispatch('Round:RoundOver')
		announceMessage = 'Round over.'
	end

	if self._announceInChat then
		ChatManager:SendMessage(announceMessage)
	end
end

return Round