classdef DiffDriveFollower < control
    %DIFFDRIVEFOLLOWER 
    % controller for followers in the leader-follower method
    
    properties
        type % [d,d] or [d,phi] formation
        d1
        d2
        d
        phi
    end
    
    methods
        function obj = DiffDriveFollower(type,params)
            %DIFFDRIVEFOLLOWER 
            valid_type = ["dd";"dphi"];
            if (~ismember(type,valid_type))
                msg = "follwer controller: invalid formation type";
                error(msg);
            end
            obj.type = type;
            if (strcmp(type,"dd")) % distance-distnce formation
                obj.d1 = params.d1;
                obj.d2 = params.d2;
            elseif (strcmp(type,"dphi"))
                obj.d = params.d;
                obj.phi = params.phi;
            end
        end
        
        function control = compute_control(obj,pose,lead1,lead2)
            % compute the control according to current position
            if (strcmp(obj.type,"dphi"))
                control = obj.compute_dphi(pose,lead1,obj.d,obj.phi);
            elseif (strcmp(obj.type,"dd"))
                control = obj.compute_dd(pose,lead1,lead2);
            end
        end
        
        function control = compute_dd(obj,pose,lead1,lead2)
            lead = (lead1+lead2)/2;
            x = pose(1); y = pose(2);
            if (lead1(1)<lead2(1))
                lead_1 = lead2;
                lead_2 = lead1;
            else
                lead_1 = lead1;
                lead_2 = lead2;
            end
            x_l1 = lead_1(1); y_l1 = lead_1(2);
            x_l2 = lead_2(1); y_l2 = lead_2(2);
            d_l = sqrt((x_l1-x_l2)^2+(y_l1-y_l2)^2);
            d_1 = obj.d1; d_2 = obj.d2; d_3 = d_l;
            % transform from d-d to d-phi
            d_ = obj.compute_dm(d_1,d_2,d_3);
            
            control = obj.compute_dphi(pose,lead,d_,0);
        end
        
        function control = compute_dphi(obj,pose,lead,d,phi)
            % giving the pose of leader compute control
            phi_thresh = 0.1;
            delta = 0.1;
            w = 1.5;
            v = 1.0;
            theta = pose(3);
            x = pose(1); y = pose(2);
            x_l = lead(1); y_l = lead(2);
            d_x = x_l - x;
            d_y = y_l - y;
            theta_l = angle(d_x + 1j*d_y);
            d_phi = theta_l - (theta+phi);
            if (abs(d_phi) < phi_thresh) % ok to match d
                control.wRef = 0;
                d_ = sqrt(d_x^2 + d_y^2);
                if (d_ > d-delta)&&(d_ < d+delta)
                    control.vRef = 0;
                elseif (d_ >= d+delta)
                    control.vRef = v;
                else
                    control.vRef = -v;
                end
            else % match phi to leader first
                control.vRef = 0;
                if (d_phi > 0)
                    control.wRef = w;
                else
                    control.wRef = -w;
                end
            end
        end
        
        function dm = compute_dm(obj,d1,d2,d3)
            dm_sqr = d1^2/2 + d2^2/2 - d3^2/4;
            dm = sqrt(dm_sqr);
        end

    end
end

