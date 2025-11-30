        case 150:
            switch (arg1) {
                case 0:
                    *return_val = GetNbPuzzleFloorsEntered();
                    break;
                case 1:
                    *return_val = GetNbOrbsObtained();
                    break;
                case 2:
                    *return_val = GetNbOrbsGiven();
                    break;
                case 3:
                    *return_val = ReadBagSwapByte();
                    break;
                case 4: // Nb Orbs Obtained - Nb Orbs Given
                    *return_val = GetNbOrbsObtained();
                    *return_val -= GetNbOrbsGiven();
                    if (*return_val < 0) {
                        *return_val = 256;
                    }
                    break;
                default:
                    *return_val = 255;
                    break;
            }
            return true;
        case 151:
            *return_val = 1;
            switch (arg1) {
                case 0:
                    IncrementNbPuzzleFloorsEntered();
                    break;
                case 1:
                    IncrementNbOrbsObtained();
                    break;
                case 2:
                    IncrementNbOrbsGiven();
                    break;
                case 3:
                    WriteBagSwapByte(arg2);
                    break;
                default:
                    *return_val = 0;
                    break;
            }
            return true;
        case 152:
            RemoveOneOrbFromBags();
            return true;