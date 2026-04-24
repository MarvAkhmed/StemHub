//
//  SocialLoginViewModelProtocol.swift
//  StemHub
//
//  Created by Marwa Awad on 06.04.2026.
//

import Combine

protocol SocialLoginViewModelProtocol: ObservableObject,
                                       LaunchRouting,
                                       SocialSignInDriving {}
